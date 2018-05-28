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

        bytes2 compareSymbol;

        address account;
    }

    Admin private admin;

    uint public lockBalance;

    Token private token;

    XCPlugin private xcPlugin;

    event Lock(bytes32 toPlatform, address toAccount, bytes32 value, bytes32 tokenSymbol);

    event Unlock(string txid, bytes32 fromPlatform, address fromAccount, bytes32 value, bytes32 tokenSymbol);

    event Deposit(address from, bytes32 value);

    function XC() public payable {

        init();
    }

    function init() internal {

        // Admin {status | platformName | compareSymbol | account}
        admin.status = 3;

        admin.platformName = "ETH";

        admin.compareSymbol = "-=";

        admin.account = msg.sender;

        //totalSupply = 10 * (10 ** 8) * (10 ** 9);
        lockBalance = 10 * (10 ** 8) * (10 ** 9);

        token = Token(0xc15d8f30fa3137eee6be111c2933f1624972f45c);

        xcPlugin = XCPlugin(0x55c87c2e26f66fd3642645c3f25c9e81a75ec0f4);
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

    function lock(address toAccount, uint value) external payable {

        require(admin.status == 2 || admin.status == 3);

        require(xcPlugin.getStatus());

        require(toAccount != address(0));

        require(value > 0);

        uint allowance = token.allowance(msg.sender, this);

        require(allowance >= value);

        bool success = token.transferFrom(msg.sender, this, value);

        require(success);

        lockBalance = SafeMath.add(lockBalance, value);

        emit Lock(xcPlugin.getTrustPlatform(), toAccount, bytes32(value), xcPlugin.getTokenSymbol());
    }

    function unlock(string txid, address fromAccount, address toAccount, uint value) external payable {

        require(admin.status == 1 || admin.status == 3);

        require(xcPlugin.getStatus());

        require(toAccount != address(0));

        require(value > 0);

        bool complete;

        bool verify;

        (complete, verify) = xcPlugin.verifyProposal(fromAccount, toAccount, value, txid);

        require(verify && !complete);

        uint balance = token.balanceOf(this);

        require(balance >= value);

        require(token.transfer(toAccount, value));

        require(xcPlugin.commitProposal(txid));

        lockBalance = SafeMath.sub(lockBalance, value);

        emit Unlock(txid, xcPlugin.getTrustPlatform(), fromAccount, bytes32(value), xcPlugin.getTokenSymbol());
    }

    function withdraw(address account, uint value) external payable {

        require(admin.account == msg.sender);

        require(account != address(0));

        require(value > 0);

        uint balance = token.balanceOf(this);

        require(SafeMath.sub(balance, lockBalance) >= value);

        bool success = token.transfer(account, value);

        require(success);
    }

    function transfer(address account, uint value) external payable {

        require(admin.account == msg.sender);

        require(account != address(0));

        require(value > 0 && value <= address(this).balance);

        this.transfer(account, value);
    }

    function deposit() external payable {

        emit Deposit(msg.sender, bytes32(msg.value));
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