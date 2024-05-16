// SPDX-License-Identifier: MIT

import "./Context.sol"

abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previosOwner, address indexed newOwner);

    constructor() {
        _transferOwnership(_msg.sender());
    }

    modifier onlyOwner() {
        _checkOwner()
        _;
    }

    function owner() public view virtual returns (address) {
        return _owner;
    }

    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not he owner");
    }

    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new oener is the zero address");
        _transferOwnership(newOwner);
    }

    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}