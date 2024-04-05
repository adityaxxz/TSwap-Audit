// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import { Test, console } from "forge-std/Test.sol";
import { StdInvariant } from "forge-std/StdInvariant.sol";
import { ERC20Mock } from "../mocks/ERC20Mock.sol";
import { PoolFactory } from "../../../src/PoolFactory.sol";
import { TSwapPool } from "../../../src/TSwapPool.sol";
import { Handler } from "../invariant/Handler.t.sol";


contract Invariant is StdInvariant , Test{
    // these pools have 2 assests
    ERC20Mock poolToken;
    ERC20Mock weth;

    PoolFactory factory;
    TSwapPool pool;     // pooltoken / weth
    int256 constant STARTING_X = 100e18;        // starting ERC20
    int256 constant STARTING_Y = 50e18;         // starting WETH

    Handler handler;

    function setUp() public {
        weth = new ERC20Mock();
        poolToken = new ERC20Mock();
        factory = new  PoolFactory(address(weth));
        pool = TSwapPool(factory.createPool(address(poolToken)));

        //* Create those initial x & y balances
        poolToken.mint(address(this),uint256(STARTING_X));
        weth.mint(address(this),uint256(STARTING_Y));

        poolToken.approve(address(pool),type(uint256).max);
        weth.approve(address(pool),type(uint256).max);

        //* deposit into the pool, give those starting X & Y balances
        pool.deposit(
            uint256(STARTING_Y),
            uint256(STARTING_Y),
            uint256(STARTING_X),
            uint64(block.timestamp));
        
        handler =  new Handler(pool);
        bytes4[] memory selectors = new bytes4[](2);
        selectors[0] = handler.deposit.selector;
        selectors[1] = handler.swapPoolTokenForWethBasedOnOutputWeth.selector;

        targetSelector(FuzzSelector({addr: address(handler),selectors: selectors}));
        targetContract(address(handler));

    }

    function invariant_constantProductFormulaStaystheSameX() public {
        // assert() what??????
        // The change in the pool size of WETH should follow this funciton:
        // ∆x = (β/(1-β)) * x
        // actul delta X == ∆x = (β/(1-β)) * x

        assertEq(handler.actualDeltaX() ,handler.expectedDeltaX());

    }

    function invariant_constantProductFormulaStaystheSameY() public {
        assertEq(handler.actualDeltaY() ,handler.expectedDeltaY());
    
    }

}