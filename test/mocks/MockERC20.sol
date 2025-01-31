// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {ERC20} from "solady/tokens/ERC20.sol";

contract MockERC20 is ERC20 {
    constructor(string memory _name, string memory _symbol) {}

    function name() public pure override returns (string memory) {
        return "Mock Token";
    }

    function symbol() public pure override returns (string memory) {
        return "MOCK";
    }

    function mint(address to, uint256 amount) public {
        _mint(to, amount);
    }

    function burn(address from, uint256 amount) public {
        _burn(from, amount);
    }
}
