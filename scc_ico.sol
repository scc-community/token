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
    mapping (address => uint256) public balanceOf;
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
        require(balanceOf[_from] >= _value);
        // Check for overflows
        require(balanceOf[_to] + _value > balanceOf[_to]);
        // Save this for an assertion in the future
        uint previousBalances = balanceOf[_from] + balanceOf[_to];
        // Subtract from the sender
        balanceOf[_from] -= _value;
        // Add the same to the recipient
        balanceOf[_to] += _value;
        Transfer(_from, _to, _value);
        // Asserts are used to use static analysis to find bugs in your code. They should never fail
        assert(balanceOf[_from] + balanceOf[_to] == previousBalances);
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
        require(balanceOf[msg.sender] >= _value);   // Check if the sender has enough
        balanceOf[msg.sender] -= _value;            // Subtract from the sender
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
        require(balanceOf[_from] >= _value);                // Check if the targeted balance is enough
        require(_value <= allowance[_from][msg.sender]);    // Check allowance
        balanceOf[_from] -= _value;                         // Subtract from the targeted balance
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
contract SCCToken is BasicERC20Token {
    using SafeMath for uint256;
    string public name = "Source Code Chain Token";
    string public symbol = "SCC";
    uint public decimals = 18;

    uint[3] public exchangeNumber = [
    60000,
    52500,
    45000
    ];
    uint256[3] public phaseRemainNumber = [
    600000000 * 10 ** uint256(decimals),
    1050000000 * 10 ** uint256(decimals),
    1350000000 * 10 ** uint256(decimals)
    ];
    /// Each phase contains exactly 38117 Ethereum blocks, which is roughly 1 week,
    /// See https://www.ethereum.org/crowdsale#scheduling-a-call
    uint[3] public phaseBlock = [
    157533,
    315066,
    472599
    ];

    uint public constant NUM_OF_PHASE = 3;

    uint public currentPhase = 0;

    /// This is where we hold ETH during this token sale. We will not transfer any Ether
    /// out of this address before we invocate the `close` function to finalize the sale.
    /// This promise is not guanranteed by smart contract by can be verified with public
    /// Ethereum transactions data available on several blockchain browsers.
    /// This is the only address from which `start` and `close` can be invocated.
    ///
    /// Note: this will be initialized during the contract deployment.
    address public target;

    /// `firstblock` specifies from which block our token sale starts.
    /// This can only be modified once by the owner of `target` address.
    uint public firstblock = 0;

    /// Minimum amount of funds to be raised for the sale to succeed.
    uint public constant GOAL = 20000 ether;

    /// Maximum amount of fund to be raised, the sale ends on reaching this amount.
    uint public constant HARD_CAP = 60000 ether;

    /// A simple stat for emitting events.
    uint256 public totalEthReceived = 0;

    /// Issue event index starting from 0.
    uint public issueIndex = 0;

    /// Refund event index starting from 0.
    uint public refundIndex = 0;

    bool public isClose = false;

    struct IssueToken {
        address recipient;
        uint256 tokens;
        uint256 usingEthAmount;
    }

    IssueToken[] public issueTokens;

    /// Refund service Charge 1%
    uint public charge = 1;
    /*
     * EVENTS
     */

    /// Emitted only once after token sale starts.
    event SaleStarted();

    /// Emitted only once after token sale ended (all token issued).
    event SaleEnded();

    /// Emitted when a function is invocated by unauthorized addresses.
    event InvalidCaller(address caller);

    /// Emitted when a function is invocated without the specified preconditions.
    /// This event will not come alone with an exception.
    event InvalidState(bytes msg);

    /// Emitted for each successful token purchase.
    event Issue(uint issueIndex, address addr, uint256 ethAmount, uint256 tokenAmount);

    event IssueFail(address addr, uint256 ethAmount, uint256 tokenAmount, uint256 leaveToken);

    event Refund(uint refundIndex, address addr, uint256 ethAmount, uint256 tokenAmount);

    event TransferTarget(address fromAddr, uint256 ethAmount);

    event TurnToNextPhase(uint phase, uint blockNumber);

    /// Emitted if the token sale succeeded.
    event SaleSucceeded();

    /// Emitted if the token sale failed.
    /// When token sale failed, all Ether will be return to the original purchasing
    /// address with a minor deduction of transaction fee（gas)
    event SaleFailed();

    /*
     * MODIFIERS
     */

    modifier onlyOwner {
        if (target == msg.sender) {
            _;
        } else {
            InvalidCaller(msg.sender);
            revert();
        }
    }

    modifier beforeStart {
        if (!saleStarted()) {
            _;
        } else {
            InvalidState("Sale has not started yet");
            revert();
        }
    }

    modifier inProgress {
        if (saleStarted() && !saleEnded()) {
            _;
        } else {
            InvalidState("Sale is not in progress");
            revert();
        }
    }

    modifier afterEnd {
        if (saleEnded()) {
            _;
        } else {
            InvalidState("Sale is not ended yet");
            revert();
        }
    }

    modifier closeDone {
        if(isClose) {
            _;
        }else {
            InvalidState("Close function isn't executed");
            revert();
        }
    }

    function SCCToken(address _target) public{
        target = _target;
        totalSupply = 10000000000 * 10 ** uint256(decimals);
        balanceOf[target] = totalSupply;
    }

    function start(uint _firstblock) public onlyOwner beforeStart {
        if (_firstblock <= block.number) {
            // Must specify a block in the future.
            revert();
        }
        firstblock = _firstblock;
        currentPhase = 0;
        SaleStarted();
    }

    function close() public onlyOwner afterEnd {
        if (totalEthReceived < GOAL) {
            refund();
            SaleFailed();
        } else {
            SaleSucceeded();
        }
        isClose = true;
    }

    function price() public constant returns (uint tokens) {
        if(currentPhase < NUM_OF_PHASE) {
            return exchangeNumber[currentPhase];
        }else {
            return exchangeNumber[NUM_OF_PHASE - 1];
        }
    }

    function updateCurrentPhase() internal {
        while(currentPhase < NUM_OF_PHASE && block.number - firstblock >= phaseBlock[currentPhase]) {
            currentPhase += 1;
        }
    }

    function withdraw() public onlyOwner closeDone {
        if(!target.send(this.balance)) {
            revert();
        }
    }

//    function setCurrentPhase(uint phase) public onlyOwner {
//        if(phase >= NUM_OF_PHASE) {
//            phase = NUM_OF_PHASE;
//        }
//        if(currentPhase < phase) {
//            currentPhase = phase;
//        }
//    }

    function () payable public{
        issueToken(msg.sender);
    }


    function issueToken(address recipient) payable inProgress public{
        // We only accept minimum purchase of 0.01 ETH.
        assert(msg.value >= 0.01 ether);
        // We only accept maximum purchase of 1000 ETH
        assert(msg.value <= 1000 ether);

        assert(currentPhase < NUM_OF_PHASE);
        uint256 tokens;
        uint256 usingEthAmount;
        (tokens, usingEthAmount) = computeTokenAmount(msg.value);

        // Check balance again
        if(balanceOf[target] < tokens) {
            IssueFail(
                recipient,
                msg.value,
                tokens,
                balanceOf[target]
            );
            revert();
        }
        totalEthReceived = totalEthReceived.add(usingEthAmount);
        balanceOf[target] = balanceOf[target].sub(tokens);
        balanceOf[recipient] = balanceOf[recipient].add(tokens);

        Issue(
            issueIndex++,
            recipient,
            usingEthAmount,
            tokens
        );

        issueTokens.push(IssueToken({
            recipient: recipient,
            usingEthAmount: usingEthAmount,
            tokens: tokens
            }));

        //        if (!target.send(usingEthAmount)) {
        //            revert();
        //        }

        if(usingEthAmount < msg.value) {
            uint256 returnEthAmount = msg.value - usingEthAmount;
            if(!recipient.send(returnEthAmount)) {
                revert();
            }
        }
    }

    function computeTokenAmount(uint256 ethAmount) internal returns (uint256 tokens, uint256 usingEthAmount) {
        updateCurrentPhase();
        if(currentPhase >= NUM_OF_PHASE) {
            revert();
        }
        tokens = ethAmount.mul(exchangeNumber[currentPhase]);
        if(tokens < phaseRemainNumber[currentPhase]) {
            usingEthAmount = ethAmount;
            phaseRemainNumber[currentPhase] = phaseRemainNumber[currentPhase].sub(tokens);
        }else if(tokens == phaseRemainNumber[currentPhase]) {
            phaseRemainNumber[currentPhase] = 0;
            usingEthAmount = ethAmount;
            currentPhase += 1;
        }else {
            uint256 remainTokens = phaseRemainNumber[currentPhase];
            uint256 costEthAmount = remainTokens.div(exchangeNumber[currentPhase]);
            phaseRemainNumber[currentPhase] = 0;
            currentPhase += 1;
            if(currentPhase >= NUM_OF_PHASE) {
                usingEthAmount = costEthAmount;
                tokens = remainTokens;
            }else {
                uint256 remainEthAmount = ethAmount.sub(costEthAmount);
                uint256 allocationTokens = remainEthAmount.mul(exchangeNumber[currentPhase]);
                tokens = allocationTokens.add(remainTokens);
                usingEthAmount = ethAmount;
            }
        }
    }

    function refund() internal {
        for(uint i=0; i<issueTokens.length; i++) {
            uint256 tokens = issueTokens[i].tokens;
            address recipient = issueTokens[i].recipient;

            /// Make sure that address owner has enough tokens to refund
            if(balanceOf[recipient] >= tokens) {
                balanceOf[recipient] = balanceOf[recipient].sub(tokens);
                balanceOf[target] = balanceOf[target].add(tokens);

                uint256 refundCharge = issueTokens[i].usingEthAmount.div(100).mul(charge);
                uint256 refundAmount = issueTokens[i].usingEthAmount.sub(refundCharge);

                if(!recipient.send(refundAmount)) {
                    revert();
                }
                Refund(
                    refundIndex++,
                    recipient,
                    refundAmount,
                    tokens
                );
            }
        }
    }

    function saleStarted() public constant returns (bool) {
        return (firstblock > 0 && block.number >= firstblock);
    }

    function saleEnded() public constant returns (bool) {
        return firstblock > 0
            && ((currentPhase >= NUM_OF_PHASE) || (block.number - firstblock > phaseBlock[NUM_OF_PHASE-1]) || hardCapReached());
    }

    function hardCapReached() public constant returns (bool) {
        return totalEthReceived >= HARD_CAP;
    }
}
