pragma solidity ^0.4.19;

import "./XCInterface.sol";

import "./Token.sol";

import "./XCPlugin.sol";

import "./SafeMath.sol";

contract XC is XCInterface {

    /**
     * Contract Administrator
     * @field status Contract external service status.
     * @field platformName Current contract platform name.
     * @field account Current contract administrator.
     */
    struct Admin {

        uint8 status;

        bytes32 platformName;

        bytes32 tokenSymbol;

        bytes2 compareSymbol;

        address account;
    }

    Admin private admin;

    uint public lockBalance;

    Token private token;

    XCPlugin private xcPlugin;

    event Lock(bytes32 toPlatform, address toAccount, bytes32 value, bytes32 tokenSymbol);

    event Unlock(string txid, bytes32 fromPlatform, address fromAccount, bytes32 value, bytes32 tokenSymbol);

    function XC() public payable {

        init();
    }

    function init() internal {

        // Admin {status | platformName | tokenSymbol | compareSymbol | account}
        admin.status = 3;

        admin.platformName = "QTUM";

        admin.tokenSymbol = "INK";

        admin.compareSymbol = "-=";

        admin.account = msg.sender;

        //totalSupply = 10 * (10 ** 8) * (10 ** 9);
        lockBalance = 0;

        token = Token(0x7415e052a2343942180a0b04c96bdb817fbc6243);

        xcPlugin = XCPlugin(0x1acab32adec81c340c7b3cf10e09d389068eb771);
    }

    function setStatus(uint8 status) external {

        require(admin.account == msg.sender);

        require(status == 0 || status == 1 || status == 2 || status == 3);

        if (admin.status != status) {

            admin.status = status;
        }
    }

    function getStatus() external view returns (uint8) {

        return admin.status;
    }

    function getPlatformName() external view returns (bytes32) {

        return admin.platformName;
    }

    function setAdmin(address account) external {

        require(account != address(0));

        require(admin.account == msg.sender);

        if (admin.account != account) {

            admin.account = account;
        }
    }

    function getAdmin() external view returns (address) {

        return admin.account;
    }

    function setToken(address account) external {

        require(admin.account == msg.sender);

        if (token != account) {

            token = Token(account);
        }
    }

    function getToken() external view returns (address) {

        return token;
    }

    function setXCPlugin(address account) external {

        require(admin.account == msg.sender);

        if (xcPlugin != account) {

            xcPlugin = XCPlugin(account);
        }
    }

    function getXCPlugin() external view returns (address) {

        return xcPlugin;
    }

    function setCompare(bytes2 symbol) external {

        require(admin.account == msg.sender);

        require(symbol == "+=" || symbol == "-=");

        if (admin.compareSymbol != symbol) {

            admin.compareSymbol = symbol;
        }
    }

    function getCompare() external view returns (bytes2){

        require(admin.account == msg.sender);

        return admin.compareSymbol;
    }

    function lock(bytes32 toPlatform, address toAccount, uint value) external payable {

        require(admin.status == 2 || admin.status == 3);

        require(xcPlugin.getStatus());

        require(xcPlugin.existPlatform(toPlatform));

        require(toAccount != address(0));

        // require(uint(token.totalSupply) >= value && value > 0);
        require(value > 0);

        //get user approve the contract quota
        uint allowance = token.allowance(msg.sender, this);

        require(toCompare(allowance, value));

        //do transferFrom
        bool success = token.transferFrom(msg.sender, this, value);

        require(success);

        //record the amount of local platform turn out
        lockBalance = SafeMath.add(lockBalance, value);
        // require(token.totalSupply >= lockBalance);

        //trigger lockEvent
        emit Lock(toPlatform, toAccount, bytes32(value), admin.tokenSymbol);
    }

    //turn in
    function unlock(string txid, bytes32 fromPlatform, address fromAccount, address toAccount, uint value) external payable {

        require(admin.status == 1 || admin.status == 3);

        require(xcPlugin.getStatus());

        require(xcPlugin.existPlatform(fromPlatform));

        require(toAccount != address(0));

        // require(token.totalSupply >= value && value > 0);
        require(value > 0);

        bool complete;

        bool verify;

        //verify args by function xcPlugin.verify
        (complete, verify) = xcPlugin.verifyProposal(fromPlatform, fromAccount, toAccount, value, admin.tokenSymbol, txid);

        require(verify && !complete);

        //get contracts balance
        uint balance = token.balanceOf(this);

        //validate the balance of contract were less than amount
        require(toCompare(balance, value));

        // require(token.transfer(toAccount, value));
        token.transfer(toAccount, value);

        require(xcPlugin.commitProposal(fromPlatform, txid));

        lockBalance = SafeMath.sub(lockBalance, value);

        emit Unlock(txid, fromPlatform, fromAccount, bytes32(value), admin.tokenSymbol);
    }

    function withdraw(address account, uint value) external payable {

        require(admin.account == msg.sender);

        require(account != address(0));

        require(value > 0);

        uint balance = token.balanceOf(this);

        require(toCompare(SafeMath.sub(balance, lockBalance), value));

        token.transfer(account, value);
    }

    function transfer(address account, uint value) external payable {

        require(admin.account == msg.sender);

        require(account != address(0));

        require(value > 0 && value >= address(this).balance);

        this.transfer(account, value);
    }

    /**
     *   ######################
     *  #  private function  #
     * ######################
     */

    function toCompare(uint f, uint s) internal view returns (bool) {

        if (admin.compareSymbol == "-=") {

            return f > s;
        } else if (admin.compareSymbol == "+=") {

            return f >= s;
        } else {

            return false;
        }
    }
}