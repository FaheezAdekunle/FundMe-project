// unit
// integrations <- coming back to do this later
// forked
// staging <- run test on a mainnet or testnet

// fuzzing
// stateful fuzz
// stateless fuzz
// formal verification

// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

import {Test} from "forge-std/Test.sol";
import {DeployRaffle} from "script/DeployRaffle.s.sol";
import {Raffle} from "src/Raffle.sol";
import {HelperConfig} from "script/HelperConfig.s.sol";
import {Vm} from "forge-std/Vm.sol";
import {VRFCoordinatorV2_5Mock} from "@chainlink/contracts/src/v0.8/vrf/mocks/VRFCoordinatorV2_5Mock.sol";
import {CodeConstants} from "script/HelperConfig.s.sol";
import {CreateSubscription, FundSubscription, AddConsumer} from "script/Interactions.s.sol";
import {LinkToken} from "test/mocks/LinkToken.sol";

contract InteractionsTest is CodeConstants, Test {
    Raffle public raffle;
    HelperConfig public helperConfig;

    uint256 entranceFee;
    uint256 interval;
    address vrfCoordinator;
    bytes32 gasLane;
    uint256 subscriptionId;
    uint32 callbackGasLimit;
    address linkToken;
    address account;

    address public PLAYER = makeAddr("player");
    uint256 public constant STARTING_PLAYER_BALANCE = 10 ether;

    function setUp() external {
        DeployRaffle deployer = new DeployRaffle();
        (raffle, helperConfig) = deployer.deployContract();
        HelperConfig.NetworkConfig memory config = helperConfig.getConfig();
        entranceFee = config.entranceFee;
        interval = config.interval;
        vrfCoordinator = config.vrfCoordinator;
        gasLane = config.gasLane;
        callbackGasLimit = config.callbackGasLimit;
        subscriptionId = config.subscriptionId;
        linkToken = config.link;
        account = config.account;

        vm.deal(PLAYER, STARTING_PLAYER_BALANCE);
    }

    function testCreateSubscriptionUsingConfigReturnsSubIdAndVrfcoordinator() public {
        // Arrange
        CreateSubscription createSubscription = new CreateSubscription(helperConfig);

        // Act
        (uint256 subId, address returnedCoordinator) = createSubscription.createSubscriptionUsingConfig();

        // Assert
        assertEq(returnedCoordinator, vrfCoordinator, "Returned coordinator should match config");
        assertGt(subId, 0, "Subscription Id should be greater than 0");
    }

    function testCreateSubscriptionReturnsSubIdAndVrfCoordinator() public {
        // Arrange
        CreateSubscription createSubscription = new CreateSubscription(helperConfig);

        // Act
        (uint256 subId, address returnedCoordinator) = createSubscription.createSubscription(vrfCoordinator, account);

        // Assert
        assertEq(returnedCoordinator, vrfCoordinator, "Returned coordinator should match config");
        assertGt(subId, 0, "Subscription Id should be greater than 0");
    }

    function testUserCanFundInteractionsUsingConfig() public {
        VRFCoordinatorV2_5Mock coordinator = VRFCoordinatorV2_5Mock(vrfCoordinator);
        uint256 subscriptionId = coordinator.createSubscription();

        FundSubscription fundSub = new FundSubscription();
        fundSub.fundSubscriptionUsingConfig();
    }

    function testUserCanFundInteractions() public {
        VRFCoordinatorV2_5Mock coordinator = VRFCoordinatorV2_5Mock(vrfCoordinator);
        uint256 subscriptionId = coordinator.createSubscription();

        FundSubscription fundSub = new FundSubscription();
        fundSub.fundSubscription(vrfCoordinator, subscriptionId, linkToken, account);
    }

    function testAddConsumerToAddConsumerToSubscription() public {
        VRFCoordinatorV2_5Mock coordinator = VRFCoordinatorV2_5Mock(vrfCoordinator);
        vm.startPrank(account);
        uint256 subscriptionId = coordinator.createSubscription();

        vm.stopPrank();

        AddConsumer addConsumer = new AddConsumer();
        addConsumer.addConsumer(address(raffle), vrfCoordinator, subscriptionId, account);
    }

    function testAddConsumerToAddConsumerUsingConfigToSubscription() public {
        VRFCoordinatorV2_5Mock coordinator = VRFCoordinatorV2_5Mock(vrfCoordinator);
        vm.startPrank(account);
        uint256 subscriptionId = coordinator.createSubscription();

        vm.stopPrank();
        
        AddConsumer addConsumer = new AddConsumer();
        addConsumer.addConsumerUsingConfig(address(raffle));
    }

}
