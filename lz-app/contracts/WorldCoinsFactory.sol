// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.22;

import { ERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { OApp, MessagingFee, Origin } from "@layerzerolabs/oapp-evm/contracts/oapp/OApp.sol";

contract WorldCoinsFactory is ERC20, OApp {
    /// @notice The WLD token used for payment
    IERC20 public immutable WLD;
    
    /// @notice Mapping to track which addresses have already claimed
    mapping(address => bool) public hasClaimed;
    
    /// @notice Amount of WLD required to claim (1 WLD = 1e18 wei)
    uint256 public constant CLAIM_PRICE = 1 ether;
    
    /// @notice Amount of WLC tokens minted per claim (100 WLC = 100e18 wei)
    uint256 public constant CLAIM_AMOUNT = 100 ether;

    /// @notice Initialize with LayerZero endpoint and WLD token address
    /// @param _endpoint The local chain's LayerZero Endpoint address
    /// @param _wldToken The WLD token contract address
    constructor(address _endpoint, address _wldToken) 
        ERC20("WorldCoins", "WLC") 
        OApp(_endpoint, msg.sender)
        Ownable(msg.sender)
    {
        WLD = IERC20(_wldToken);
    }

    /// @notice Claim WLC tokens by paying WLD (one-time per address)
    /// @dev Users must approve this contract to spend their WLD tokens first
    function claim() external {
        require(!hasClaimed[msg.sender], "Already claimed");
        require(WLD.transferFrom(msg.sender, address(this), CLAIM_PRICE), "WLD payment failed");
        
        hasClaimed[msg.sender] = true;
        _mint(msg.sender, CLAIM_AMOUNT);
    }

    /// @notice Override required by OApp for cross-chain messaging
    /// @dev This implementation is minimal since we don't need cross-chain messaging for the core claim functionality
    function _lzReceive(
        Origin calldata, // _origin
        bytes32, // _guid
        bytes calldata, // _message
        address, // _executor
        bytes calldata // _extraData
    ) internal override {
        // No-op for this implementation
        // In a full implementation, this would handle cross-chain messages
    }
} 