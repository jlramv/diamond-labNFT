// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.23;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract CPSERC20 is ERC20  {
    constructor() ERC20("$CPS", "CPS") {
        _mint(msg.sender, 10000);
    }

    function mint(address account, uint256 amount) public {
        _mint(account, amount);
    }
}