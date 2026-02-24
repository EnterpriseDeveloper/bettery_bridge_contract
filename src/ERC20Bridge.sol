// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol";
import "openzeppelin-contracts/contracts/access/Ownable.sol";
import "openzeppelin-contracts/contracts/utils/Pausable.sol";
import "openzeppelin-contracts/contracts/utils/ReentrancyGuard.sol";

contract ERC20Bridge is ReentrancyGuard, Pausable, Ownable {
    using SafeERC20 for IERC20;

    struct Claim {
        uint256 evmChainId;
        address token;
        address to;
        uint256 amount;
        uint256 nonce;
    }

    uint256 public lockNonce;
    uint256 public unlockNonce;

    uint256 public immutable chainId;
    uint256 public threshold;

    mapping(address => bool) public supportedTokens;
    mapping(uint256 => bool) public processedUnlockNonces;
    mapping(address => bool) public relayers;

    event Locked(
        address indexed token,
        address indexed sender,
        string cosmosRecipient,
        uint256 amount,
        uint256 nonce
    );

    event Unlocked(
        address indexed token,
        address indexed to,
        uint256 amount,
        uint256 nonce
    );

    constructor(uint256 _threshold) Ownable(msg.sender) {
        chainId = block.chainid;
        threshold = _threshold;
    }

    function addRelayer(address relayer) external onlyOwner {
        relayers[relayer] = true;
    }

    function removeRelayer(address relayer) external onlyOwner {
        relayers[relayer] = false;
    }

    function setSupportedToken(address token, bool status) external onlyOwner {
        supportedTokens[token] = status;
    }

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }

    // -----------------------------
    // LOCK (EVM → Cosmos)
    // -----------------------------

    function lock(
        address token,
        uint256 amount,
        string calldata cosmosRecipient
    ) external nonReentrant whenNotPaused {
        require(supportedTokens[token], "unsupported token");
        require(amount > 0, "zero amount");

        lockNonce++;

        IERC20(token).safeTransferFrom(
            msg.sender,
            address(this),
            amount
        );

        emit Locked(
            token,
            msg.sender,
            cosmosRecipient,
            amount,
            lockNonce
        );
    }

    // -----------------------------
    // UNLOCK (Cosmos → EVM)
    // -----------------------------

    function unlock(
        Claim calldata claim,
        bytes[] calldata signatures
    ) external nonReentrant whenNotPaused {

        require(claim.evmChainId == chainId, "wrong chain");
        require(!processedUnlockNonces[claim.nonce], "already processed");
        require(supportedTokens[claim.token], "unsupported token");

        bytes32 messageHash = getMessageHash(claim);

        uint256 validSignatures = 0;
        address[] memory seen = new address[](signatures.length);

        for (uint256 i = 0; i < signatures.length; i++) {
            address signer = recoverSigner(messageHash, signatures[i]);

            if (relayers[signer] && !isDuplicate(seen, signer)) {
                seen[i] = signer;
                validSignatures++;
            }
        }

        require(validSignatures >= threshold, "not enough signatures");

        processedUnlockNonces[claim.nonce] = true;

        IERC20(claim.token).safeTransfer(claim.to, claim.amount);

        emit Unlocked(
            claim.token,
            claim.to,
            claim.amount,
            claim.nonce
        );
    }

    // -----------------------------
    // INTERNAL
    // -----------------------------

    function getMessageHash(Claim calldata claim)
        public
        pure
        returns (bytes32)
    {
        return keccak256(
            abi.encode(
                claim.evmChainId,
                claim.token,
                claim.to,
                claim.amount,
                claim.nonce
            )
        );
    }

    function recoverSigner(bytes32 hash, bytes memory signature)
        internal
        pure
        returns (address)
    {
        bytes32 ethSignedHash = keccak256(
            abi.encodePacked("\x19Ethereum Signed Message:\n32", hash)
        );

        (bytes32 r, bytes32 s, uint8 v) = splitSignature(signature);
        return ecrecover(ethSignedHash, v, r, s);
    }

    function splitSignature(bytes memory sig)
        internal
        pure
        returns (bytes32 r, bytes32 s, uint8 v)
    {
        require(sig.length == 65, "invalid signature");

        assembly {
            r := mload(add(sig, 32))
            s := mload(add(sig, 64))
            v := byte(0, mload(add(sig, 96)))
        }
    }

    function isDuplicate(address[] memory arr, address signer)
        internal
        pure
        returns (bool)
    {
        for (uint256 i = 0; i < arr.length; i++) {
            if (arr[i] == signer) {
                return true;
            }
        }
        return false;
    }
}