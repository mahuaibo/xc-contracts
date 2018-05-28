pragma solidity ^0.4.13;

import "./SafeMath.sol";

contract ERC20 {

    uint256 public totalSupply;

    mapping(address => uint256) public balanceOf;

    mapping(address => mapping(address => uint256)) public allowance;

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);

    function transfer(address _to, uint256 _value) public returns (bool success) {

        _transfer(msg.sender, _to, _value);

        return true;
    }

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {

        require(allowance[_from][msg.sender] >= _value);

        allowance[_from][msg.sender] = SafeMath.sub(allowance[_from][msg.sender], _value);

        _transfer(_from, _to, _value);

        return true;
    }

    function approve(address _spender, uint256 _value) public returns (bool success) {

        allowance[msg.sender][_spender] = _value;

        emit Approval(msg.sender, _spender, _value);

        return true;
    }

    /**
     *   ######################
     *  #  private function  #
     * ######################
     */

    function _transfer(address _from, address _to, uint _value) internal {

        require(balanceOf[_from] >= _value);

        require(SafeMath.add(balanceOf[_to], _value) >= balanceOf[_to]);

        balanceOf[_from] = SafeMath.sub(balanceOf[_from], _value);

        balanceOf[_to] = SafeMath.add(balanceOf[_to], _value);

        emit Transfer(_from, _to, _value);
    }
}

contract Token is ERC20 {

    uint8 public constant decimals = 9;

    uint256 public constant initialSupply = 10 * (10 ** 8) * (10 ** uint256(decimals));

    string public constant name = 'INK Coin';

    string public constant symbol = 'INK';


    function() public {

        revert();
    }

    function Token() public {

        balanceOf[msg.sender] = initialSupply;

        totalSupply = initialSupply;
    }

    function approveAndCall(address _spender, uint256 _value, bytes _extraData) public returns (bool success) {

        if (approve(_spender, _value)) {

            if (!_spender.call(bytes4(bytes32(sha3("receiveApproval(address,uint256,address,bytes)"))), msg.sender, _value, this, _extraData)) {

                revert();
            }

            return true;
        }
    }

}