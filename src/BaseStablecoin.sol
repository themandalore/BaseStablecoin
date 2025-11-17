// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.25;

import {Token} from "./Token.sol";

/**
 @title BaseStablecoin
 @dev a stablecoin
 */
contract BaseStablecoin is Token{
    //storage
    address public admin;//admin, controls pause, blacklist functionality, and mintContract address
    address public mintContract;//mint contract that can mint/burn
    address public proposedMintContract;
    address public proposedAdmin;
    uint256 public proposalTime;
    mapping(address => bool) public blacklisted;

    //events
    event BlacklistStatusChanged(address _addy, bool _status);
    event SystemUpdateProposal(address _proposedAdmin, address _proposedMintContract);
    event SystemVariablesUpdated(address _admin, address _mintContract);

    //functions
    /**
     * @dev starts the stablecoin system
     * @param _admin admin in the contract
     * @param _mintContract party with the mint contract
     * @param _name this is the name of the token (standard ERC20)
     * @param _symbol this is the token symbol (standard ERC20)
     * must also initialize the mint contract in the system to fully start
     */
    constructor(address _admin,address _mintContract,string memory _name, string memory _symbol) Token(_name,_symbol){
        admin = _admin;
        mintContract = _mintContract;
    }

    /**
     * @dev function for the admin to blacklist update an array
     * @param _addresses addresses of users to blacklist (or unblacklist)
     * @param _set array of bool values to update addresses to (true = blacklisted)
     */
    function blacklistUpdate(address[] memory _addresses,bool[] memory _set) external{
        require(_addresses.length == _set.length);
        require(msg.sender == admin);
        for(uint _i=0;_i<_addresses.length;_i++){
            blacklisted[_addresses[_i]] = _set[_i];
            emit BlacklistStatusChanged(_addresses[_i], _set[_i]);
        }
    }

    /**
     * @dev function for the admin to update the blacklist status of a user
     * @param _addy address to blacklist (or unblacklist)
     * @param _set bool values to update address to (true = blacklisted)
     */
    function blacklistUser(address _addy,bool _set) external{
        require(msg.sender == admin);
        blacklisted[_addy] = _set;
        emit BlacklistStatusChanged(_addy, _set);
    }

    /**
     * @dev function for the mintContract to burn tokens
     * @param _from address to burn tokens from
     * @param _amount of tokens to burn
     */
    function burn(address _from,uint256 _amount) external{
        require(msg.sender == mintContract);
        _burn(_from,_amount);
    }

    /**
     * @dev function to change the admin/mint Contract
     * @param _proposedAdmin address of new admin
     * @param _proposedMintContract address of new mint contract
     */
    function updateSystemVariables(address _proposedAdmin, address _proposedMintContract) external{
        require(msg.sender == admin);
        require(_proposedMintContract != address(0));
        proposalTime = block.timestamp;
        proposedAdmin = _proposedAdmin;
        proposedMintContract = _proposedMintContract;
        emit SystemUpdateProposal(_proposedAdmin, _proposedMintContract);
    }
    
    /**
     * @dev function to finalize an update after 7 days
     */
    function finalizeUpdate() external{
        require(msg.sender == admin);
        require(block.timestamp - proposalTime > 7 days);
        mintContract = proposedMintContract;
        admin = proposedAdmin;
        emit SystemVariablesUpdated(admin, mintContract);
    }
    
    /**
     * @dev function for the mint contract to mint tokens
     * @param _to address to mint tokens to
     * @param _amount of tokens to mint
     */
    function mint(address _to,uint256 _amount) external{
        require(msg.sender == mintContract);
        _mint(_to,_amount);
    }

    /*Getters*/
    /**
     * @dev function retrieve blacklist status
     * @param _addy address of interest
     * @return bool of is blacklisted
     */
    function isBlacklisted(address _addy) external view returns(bool){
        return blacklisted[_addy];
    }

    /*Internal*/
    /** 
     * @dev overwrites token _move to add blacklist and pause restrictions
     * @param _src address of sender
     * @param _dst address of recipient
     * @param _amount amount of token to send
     */
    function _move(address _src, address _dst, uint256 _amount) internal override{
        require(!blacklisted[_src] && !blacklisted[_dst]);
        balance[_src] = balance[_src] - _amount;//will overflow if too big
        balance[_dst] = balance[_dst] + _amount;
        emit Transfer(_src, _dst, _amount);
    }
}
