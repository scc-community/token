/*

  Copyright 2018 Source Code Chain Foundation.

  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at

  http://www.apache.org/licenses/LICENSE-2.0

  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.

*/
pragma solidity ^0.4.18;


/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {

    /**
    * @dev Multiplies two numbers, throws on overflow.
    */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        assert(c / a == b);
        return c;
    }

    /**
    * @dev Integer division of two numbers, truncating the quotient.
    */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // assert(b > 0); // Solidity automatically throws when dividing by 0
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold
        return c;
    }

    /**
    * @dev Substracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
    */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }

    /**
    * @dev Adds two numbers, throws on overflow.
    */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }
}

interface tokenRecipient { function receiveApproval(address _from, uint256 _value, address _token, bytes _extraData) public; }

contract BasicERC20Token {
    // Public variables of the token
    // 18 decimals is the strongly suggested default, avoid changing it
    uint256 public totalSupply;

    // This creates an array with all balances
    mapping (address => uint256) public balance;
    mapping (address => mapping (address => uint256)) public allowance;

    // This generates a public event on the blockchain that will notify clients
    event Transfer(address indexed from, address indexed to, uint256 value);

    // This notifies clients about the amount burnt
    event Burn(address indexed from, uint256 value);

    /**
     * Internal transfer, only can be called by this contract
     */
    function _transfer(address _from, address _to, uint _value) internal {
        // Prevent transfer to 0x0 address. Use burn() instead
        require(_to != 0x0);
        // Check if the sender has enough
        require(balance[_from] >= _value);
        // Check for overflows
        require(balance[_to] + _value > balance[_to]);
        // Save this for an assertion in the future
        uint previousBalances = balance[_from] + balance[_to];
        // Subtract from the sender
        balance[_from] -= _value;
        // Add the same to the recipient
        balance[_to] += _value;
        Transfer(_from, _to, _value);
        // Asserts are used to use static analysis to find bugs in your code. They should never fail
        assert(balance[_from] + balance[_to] == previousBalances);
    }

    /**
     * Transfer tokens
     *
     * Send `_value` tokens to `_to` from your account
     *
     * @param _to The address of the recipient
     * @param _value the amount to send
     */
    function transfer(address _to, uint256 _value) public {
        _transfer(msg.sender, _to, _value);
    }

    /**
     * Transfer tokens from other address
     *
     * Send `_value` tokens to `_to` on behalf of `_from`
     *
     * @param _from The address of the sender
     * @param _to The address of the recipient
     * @param _value the amount to send
     */
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        require(_value <= allowance[_from][msg.sender]);     // Check allowance
        allowance[_from][msg.sender] -= _value;
        _transfer(_from, _to, _value);
        return true;
    }

    /**
     * Set allowance for other address
     *
     * Allows `_spender` to spend no more than `_value` tokens on your behalf
     *
     * @param _spender The address authorized to spend
     * @param _value the max amount they can spend
     */
    function approve(address _spender, uint256 _value) public
    returns (bool success) {
        allowance[msg.sender][_spender] = _value;
        return true;
    }

    /**
     * Set allowance for other address and notify
     *
     * Allows `_spender` to spend no more than `_value` tokens on your behalf, and then ping the contract about it
     *
     * @param _spender The address authorized to spend
     * @param _value the max amount they can spend
     * @param _extraData some extra information to send to the approved contract
     */
    function approveAndCall(address _spender, uint256 _value, bytes _extraData)
    public
    returns (bool success) {
        tokenRecipient spender = tokenRecipient(_spender);
        if (approve(_spender, _value)) {
            spender.receiveApproval(msg.sender, _value, this, _extraData);
            return true;
        }
    }

    /**
     * Destroy tokens
     *
     * Remove `_value` tokens from the system irreversibly
     *
     * @param _value the amount of money to burn
     */
    function burn(uint256 _value) public returns (bool success) {
        require(balance[msg.sender] >= _value);   // Check if the sender has enough
        balance[msg.sender] -= _value;            // Subtract from the sender
        totalSupply -= _value;                      // Updates totalSupply
        Burn(msg.sender, _value);
        return true;
    }

    /**
     * Destroy tokens from other account
     *
     * Remove `_value` tokens from the system irreversibly on behalf of `_from`.
     *
     * @param _from the address of the sender
     * @param _value the amount of money to burn
     */
    function burnFrom(address _from, uint256 _value) public returns (bool success) {
        require(balance[_from] >= _value);                // Check if the targeted balance is enough
        require(_value <= allowance[_from][msg.sender]);    // Check allowance
        balance[_from] -= _value;                         // Subtract from the targeted balance
        allowance[_from][msg.sender] -= _value;             // Subtract from the sender's allowance
        totalSupply -= _value;                              // Update totalSupply
        Burn(_from, _value);
        return true;
    }
}


/**
 * @title Source Code Chain Token.
 * @author Bertrand Huang - <bertrand.huang@sourcecc.io>.
 */
contract SCCAIToken is BasicERC20Token {
    using SafeMath for uint256;
    string public name = "Source Code Chain Token";
    string public symbol = "SCCAI";
    uint public decimals = 18;

    uint public exchange = 60000;

    address public target;

    address public foundationTarget;

    uint256 public totalEthReceived = 0;

    uint public issueIndex = 0;

    bool public isStart = false;

    bool public isClose = false;

    event InvalidCaller(address caller);

    event InvalidState(bytes msg);

    event Issue(uint issueIndex, address addr, uint256 ethAmount, uint256 tokenAmount);

    modifier onlyOwner {
        if (target == msg.sender) {
            _;
        } else {
            InvalidCaller(msg.sender);
            revert();
        }
    }

    modifier inProgress {
        if(isStart && !isClose) {
            _;
        }else {
            InvalidState("Not in progress!");
            revert();
        }
    }

    function SCCAIToken(address _target, address _foundationTarget) public{
        target = _target;
        foundationTarget = _foundationTarget;
        totalSupply = 10000000000 * 10 ** uint256(decimals);
        balance[target] = 3000000000 * 10 ** uint256(decimals);
        balanceOf[foundationTarget] = 7000000000 * 10 ** uint256(decimals);
    }

    function open() public onlyOwner {
        isStart = true;
        isClose = false;
    }

    function close() public onlyOwner inProgress {
        isStart = false;
        isClose = true;
    }

    function () payable public{
        issueToken(msg.sender);
    }


    function issueToken(address recipient) payable inProgress public{
        assert(balance[target] > 0);
        uint256 tokens;
        uint256 usingEthAmount;
        (tokens, usingEthAmount) = computeTokenAmount(msg.value);

        totalEthReceived = totalEthReceived.add(usingEthAmount);
        balance[target] = balance[target].sub(tokens);
        balance[recipient] = balance[recipient].add(tokens);

        Issue(
            issueIndex++,
            recipient,
            usingEthAmount,
            tokens
        );

        if (!target.send(usingEthAmount)) {
            revert();
        }

        if(usingEthAmount < msg.value) {
            uint256 returnEthAmount = msg.value - usingEthAmount;
            if(!recipient.send(returnEthAmount)) {
                revert();
            }
        }
    }

    function computeTokenAmount(uint256 ethAmount) internal returns (uint256 tokens, uint256 usingEthAmount) {
        tokens = ethAmount.mul(exchange);
        if(tokens <= balance[target]) {
            usingEthAmount = ethAmount;
        }else {
            tokens = balance[target];
            usingEthAmount = remainTokens.div(exchange);
        }
    }

}
