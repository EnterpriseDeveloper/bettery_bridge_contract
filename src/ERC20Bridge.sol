// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
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
    uint256 public lockedAmount;
    uint256 public unlockedAmount;

    mapping(address => bool) public supportedTokens;
    mapping(uint256 => bool) public processedUnlockNonces;

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

    constructor() Ownable(msg.sender) {
        chainId = block.chainid;
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
        lockedAmount += amount;

        IERC20(token).safeTransferFrom(msg.sender, address(this), amount);

        emit Locked(token, msg.sender, cosmosRecipient, amount, lockNonce);
    }

    // -----------------------------
    // UNLOCK (Cosmos → EVM)
    // -----------------------------

    function unlock(
        Claim calldata claim
    ) external onlyOwner nonReentrant whenNotPaused {
        require(claim.evmChainId == chainId, "wrong chain");
        require(!processedUnlockNonces[claim.nonce], "already processed");
        require(supportedTokens[claim.token], "unsupported token");
        require(claim.amount > 0, "zero amount");

        processedUnlockNonces[claim.nonce] = true;
        unlockedAmount += claim.amount;

        IERC20(address(claim.token)).approve(address(this), claim.amount);
        IERC20(address(claim.token)).safeTransferFrom(
            address(this),
            claim.to,
            claim.amount
        );
        //IERC20(address(claim.token)).safeTransfer(claim.to, claim.amount);

        emit Unlocked(claim.token, claim.to, claim.amount, claim.nonce);
    }
}
