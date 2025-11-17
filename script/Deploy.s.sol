// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script, console} from "forge-std/Script.sol";
import { BaseStablecoin } from "../src/BaseStablecoin.sol";

//forge script DeployScript --rpc-url $API_KEY --verify --etherscan-api-key --broadcast

contract DeployScript is Script {
    address admin = vm.parseAddress("0x0d7effefdb084dfeb1621348c8c70cc4e871eba4");
    BaseStablecoin public token;

    function run() public {
        uint _pk = vm.envUint("PRIVATE_KEY");
        console.log("My Address:", admin);
        vm.startBroadcast(_pk);
        token = new BaseStablecoin(admin, admin, "BaseStablecoin","USD");
        console.log("BaseStablecoin: ",address(token));
        vm.stopBroadcast();
    }
}