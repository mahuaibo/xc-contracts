pragma solidity ^0.4.19;

import "./XCPluginInterface.sol";

contract XCPlugin is XCPluginInterface {

    /**
     * Contract Administrator
     * @field status Contract external service status.
     * @field platformName Current contract platform name.
     * @field tokenSymbol token Symbol.
     * @field account Current contract administrator.
     */
    struct Admin {

        bool status;

        bytes32 platformName;

        bytes32 tokenSymbol;

        address account;

        string version;
    }

    /**
     * Transaction Proposal
     * @field status Transaction proposal status(false:pending,true:complete).
     * @field fromAccount Account of form platform.
     * @field toAccount Account of to platform.
     * @field value Transfer amount.
     * @field tokenSymbol token Symbol.
     * @field voters Proposers.
     * @field weight The weight value of the completed time.
     */
    struct Proposal {

        bool status;

        address fromAccount;

        address toAccount;

        uint value;

        address[] voters;

        uint weight;
    }

    /**
     * Trusted Platform
     * @field status Trusted platform state(false:no trusted,true:trusted).
     * @field weight weight of platform.
     * @field publicKeys list of public key.
     * @field proposals list of proposal.
     */
    struct Platform {

        bool status;

        bytes32 name;

        uint weight;

        address[] publicKeys;

        mapping(string => Proposal) proposals;
    }

    Admin private admin;

    address[] private callers;

    Platform private platform;


    function XCPlugin() public {

        init();
    }

    function init() internal {
        // Admin { status | platformName | tokenSymbol | account}
        admin.status = true;

        admin.platformName = "ETH";

        admin.tokenSymbol = "INK";

        admin.account = msg.sender;

        bytes32 platformName = "INK";

        platform.status = true;

        platform.name = platformName;

        platform.weight = 1;

        platform.publicKeys.push(0x4230a12f5b0693dd88bb35c79d7e56a68614b199);

        platform.publicKeys.push(0x07caf88941eafcaaa3370657fccc261acb75dfba);
    }

    function start() external {

        require(admin.account == msg.sender);

        if (!admin.status) {

            admin.status = true;
        }
    }

    function stop() external {

        require(admin.account == msg.sender);

        if (admin.status) {

            admin.status = false;
        }
    }

    function getStatus() external view returns (bool) {

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

    function getTokenSymbol() external view returns (bytes32) {

        return admin.tokenSymbol;
    }

    function addCaller(address caller) external {

        require(admin.account == msg.sender);

        if (!_existCaller(caller)) {

            callers.push(caller);
        }
    }

    function deleteCaller(address caller) external {

        require(admin.account == msg.sender);

        if (_existCaller(caller)) {

            bool exist;

            for (uint i = 0; i <= callers.length; i++) {

                if (exist) {

                    if (i == callers.length) {

                        delete callers[i - 1];

                        callers.length--;
                    } else {

                        callers[i - 1] = callers[i];
                    }
                } else if (callers[i] == caller) {

                    exist = true;
                }
            }

        }
    }

    function existCaller(address caller) external view returns (bool) {

        return _existCaller(caller);
    }

    function getCallers() external view returns (address[]) {

        return callers;
    }

    function getTrustPlatform() external view returns (bytes32 name){

        return platform.name;
    }

    function setWeight(uint weight) external {

        require(admin.account == msg.sender);

        require(weight > 0);

        if (platform.weight != weight) {

            platform.weight = weight;
        }
    }

    function getWeight() external view returns (uint) {

        return platform.weight;
    }

    function addPublicKey(address publicKey) external {

        require(admin.account == msg.sender);

        require(publicKey != address(0));

        address[] storage listOfPublicKey = platform.publicKeys;

        for (uint i; i < listOfPublicKey.length; i++) {

            if (publicKey == listOfPublicKey[i]) {

                return;
            }
        }

        listOfPublicKey.push(publicKey);
    }

    function deletePublicKey(address publickey) external {

        require(admin.account == msg.sender);

        address[] storage listOfPublicKey = platform.publicKeys;

        bool exist;

        for (uint i = 0; i <= listOfPublicKey.length; i++) {

            if (exist) {
                if (i == listOfPublicKey.length) {

                    delete listOfPublicKey[i - 1];

                    listOfPublicKey.length--;
                } else {

                    listOfPublicKey[i - 1] = listOfPublicKey[i];
                }
            } else if (listOfPublicKey[i] == publickey) {

                exist = true;
            }
        }
    }

    function existPublicKey(address publicKey) external view returns (bool) {

        return _existPublicKey(publicKey);
    }

    function countOfPublicKey() external view returns (uint){

        return platform.publicKeys.length;
    }

    function publicKeys() external view returns (address[]){

        return platform.publicKeys;
    }

    function voteProposal(address fromAccount, address toAccount, uint value, string txid, bytes sig) external {

        require(admin.status);

        bytes32 msgHash = hashMsg(platform.name, fromAccount, admin.platformName, toAccount, value, admin.tokenSymbol, txid,admin.version);

        address publicKey = recover(msgHash, sig);

        require(_existPublicKey(publicKey));

        Proposal storage proposal = platform.proposals[txid];

        if (proposal.value == 0) {

            proposal.fromAccount = fromAccount;

            proposal.toAccount = toAccount;

            proposal.value = value;
        } else {

            require(proposal.fromAccount == fromAccount && proposal.toAccount == toAccount && proposal.value == value);
        }

        changeVoters(publicKey, txid);
    }

    function verifyProposal(address fromAccount, address toAccount, uint value, string txid) external view returns (bool, bool) {

        require(admin.status);

        Proposal storage proposal = platform.proposals[txid];

        if (proposal.status) {

            return (true, (proposal.voters.length >= proposal.weight));
        }

        if (proposal.value == 0) {

            return (false, false);
        }

        require(proposal.fromAccount == fromAccount && proposal.toAccount == toAccount && proposal.value == value);

        return (false, (proposal.voters.length >= platform.weight));
    }

    function commitProposal(string txid) external returns (bool) {

        require(admin.status);

        require(_existCaller(msg.sender) || msg.sender == admin.account);

        require(!platform.proposals[txid].status);

        platform.proposals[txid].status = true;

        platform.proposals[txid].weight = platform.proposals[txid].voters.length;

        return true;
    }

    function getProposal(string txid) external view returns (bool status, address fromAccount, address toAccount, uint value, address[] voters, uint weight){

        require(admin.status);

        fromAccount = platform.proposals[txid].fromAccount;

        toAccount = platform.proposals[txid].toAccount;

        value = platform.proposals[txid].value;

        voters = platform.proposals[txid].voters;

        status = platform.proposals[txid].status;

        weight = platform.proposals[txid].weight;

        return;
    }

    function deleteProposal(string txid) external {

        require(msg.sender == admin.account);

        delete platform.proposals[txid];
    }

    function transfer(address account, uint value) external payable {

        require(admin.account == msg.sender);

        require(account != address(0));

        require(value > 0 && value <= address(this).balance);

        this.transfer(account, value);
    }

    /**
     *   ######################
     *  #  private function  #
     * ######################
     */

    function hashMsg(bytes32 fromPlatform, address fromAccount, bytes32 toPlatform, address toAccount, uint value, bytes32 tokenSymbol, string txid,string version) internal pure returns (bytes32) {

        return sha256(bytes32ToStr(fromPlatform), ":0x", uintToStr(uint160(fromAccount), 16), ":", bytes32ToStr(toPlatform), ":0x", uintToStr(uint160(toAccount), 16), ":", uintToStr(value, 10), ":", bytes32ToStr(tokenSymbol), ":", txid, ":", version);
    }

    function changeVoters(address publicKey, string txid) internal {

        address[] storage voters = platform.proposals[txid].voters;

        bool change = true;

        for (uint i = 0; i < voters.length; i++) {

            if (voters[i] == publicKey) {

                change = false;
            }
        }

        if (change) {

            voters.push(publicKey);
        }
    }

    function bytes32ToStr(bytes32 b) internal pure returns (string) {

        uint length = b.length;

        for (uint i = 0; i < b.length; i++) {

            if (b[b.length - 1 - i] == "") {

                length -= 1;
            } else {

                break;
            }
        }

        bytes memory bs = new bytes(length);

        for (uint j = 0; j < length; j++) {

            bs[j] = b[j];
        }

        return string(bs);
    }

    function uintToStr(uint value, uint base) internal pure returns (string) {

        uint _value = value;

        uint length = 0;

        bytes16 tenStr = "0123456789abcdef";

        while (true) {

            if (_value > 0) {

                length ++;

                _value = _value / base;
            } else {

                break;
            }
        }

        if (base == 16) {
            length = 40;
        }

        bytes memory bs = new bytes(length);

        for (uint i = 0; i < length; i++) {

            bs[length - 1 - i] = tenStr[value % base];

            value = value / base;
        }

        return string(bs);
    }

    function _existCaller(address caller) internal view returns (bool) {

        for (uint i = 0; i < callers.length; i++) {

            if (callers[i] == caller) {

                return true;
            }
        }

        return false;
    }

    function _existPublicKey(address publicKey) internal view returns (bool) {


        address[] memory listOfPublicKey = platform.publicKeys;

        for (uint i = 0; i < listOfPublicKey.length; i++) {

            if (listOfPublicKey[i] == publicKey) {

                return true;
            }
        }

        return false;
    }

    function recover(bytes32 hash, bytes sig) internal pure returns (address) {

        bytes32 r;

        bytes32 s;

        uint8 v;

        assembly {

            r := mload(add(sig, 32))

            s := mload(add(sig, 64))

            v := byte(0, mload(add(sig, 96)))
        }

        if (v < 27) {

            v += 27;
        }

        return ecrecover(hash, v, r, s);
    }
}