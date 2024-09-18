
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

contract MerkleAirdrop {
    IERC20 public token;       // ERC20 token used for airdrop
    address public owner;      // Contract owner
    bytes32 public merkleRoot; // Merkle root

    mapping(address => bool) public verifiedClaimers; // Track claimers to prevent double claims

    event ClaimDetails(uint256 amount, address indexed claimer); // Emitted on successful claim

    constructor(bytes32 _merkleRoot, IERC20 _token)  {
        owner = msg.sender; // Set the contract deployer as the owner
        merkleRoot = _merkleRoot; // Set the initial Merkle root
        token = _token; // Set the ERC20 token address

         // Mint 10,000 tokens to the contract
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Not the owner");
        _;
    }

    function claimAirdrop(uint256 _amount, bytes32[] calldata _merkleProof, address claimer) external {
        require(!verifiedClaimers[claimer], "Airdrop already claimed."); // Ensure the user hasn't claimed yet

        // Create the leaf node from the claimant's address and the amount
        bytes32 leaf = keccak256(abi.encodePacked(claimer, _amount));

        // Verify the provided proof against the Merkle root
        require(MerkleProof.verify(_merkleProof, merkleRoot, leaf), "Invalid Merkle proof.");

        // Mark the claimant as having claimed their airdrop
        verifiedClaimers[claimer] = true;

        // Transfer the tokens to the claimant
        require(token.transfer(claimer, _amount), "Token transfer failed.");

        emit ClaimDetails(_amount,claimer); // Emit the claim event
    }

    // Allow the owner to update the Merkle root
    function updateMerkleRoot(bytes32 _newMerkleRoot) external onlyOwner {
        merkleRoot = _newMerkleRoot;
    }

    // Allow the owner to withdraw remaining tokens
    function withdrawRemainingTokens() external onlyOwner {
        uint256 remainingTokens = token.balanceOf(address(this));
        require(remainingTokens > 0, "No tokens to withdraw.");

        require(token.transfer(owner, remainingTokens), "Token transfer failed.");
    }

    function balanceOFAdress(address _account)external view returns (uint){

        return token.balanceOf(_account);
    }
}