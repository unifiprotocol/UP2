# Solidity API

## IAaveIncentivesController

Defines the basic interface for an Aave Incentives Controller.

### RewardsAccrued

```solidity
event RewardsAccrued(address user, uint256 amount)
```

_Emitted during &#x60;handleAction&#x60;, &#x60;claimRewards&#x60; and &#x60;claimRewardsOnBehalf&#x60;_

| Name | Type | Description |
| ---- | ---- | ----------- |
| user | address | The user that accrued rewards |
| amount | uint256 | The amount of accrued rewards |

### RewardsClaimed

```solidity
event RewardsClaimed(address user, address to, uint256 amount)
```

### RewardsClaimed

```solidity
event RewardsClaimed(address user, address to, address claimer, uint256 amount)
```

_Emitted during &#x60;claimRewards&#x60; and &#x60;claimRewardsOnBehalf&#x60;_

| Name | Type | Description |
| ---- | ---- | ----------- |
| user | address | The address that accrued rewards |
| to | address | The address that will be receiving the rewards |
| claimer | address | The address that performed the claim |
| amount | uint256 | The amount of rewards |

### ClaimerSet

```solidity
event ClaimerSet(address user, address claimer)
```

_Emitted during &#x60;setClaimer&#x60;_

| Name | Type | Description |
| ---- | ---- | ----------- |
| user | address | The address of the user |
| claimer | address | The address of the claimer |

### getAssetData

```solidity
function getAssetData(address asset) external view returns (uint256, uint256, uint256)
```

Returns the configuration of the distribution for a certain asset

| Name | Type | Description |
| ---- | ---- | ----------- |
| asset | address | The address of the reference asset of the distribution |

| Name | Type | Description |
| ---- | ---- | ----------- |
| [0] | uint256 | The asset index |
| [1] | uint256 | The emission per second |
| [2] | uint256 | The last updated timestamp |

### assets

```solidity
function assets(address asset) external view returns (uint128, uint128, uint256)
```

LEGACY **************************

_Returns the configuration of the distribution for a certain asset_

| Name | Type | Description |
| ---- | ---- | ----------- |
| asset | address | The address of the reference asset of the distribution |

| Name | Type | Description |
| ---- | ---- | ----------- |
| [0] | uint128 | The asset index, the emission per second and the last updated timestamp |
| [1] | uint128 |  |
| [2] | uint256 |  |

### setClaimer

```solidity
function setClaimer(address user, address claimer) external
```

Whitelists an address to claim the rewards on behalf of another address

| Name | Type | Description |
| ---- | ---- | ----------- |
| user | address | The address of the user |
| claimer | address | The address of the claimer |

### getClaimer

```solidity
function getClaimer(address user) external view returns (address)
```

Returns the whitelisted claimer for a certain address (0x0 if not set)

| Name | Type | Description |
| ---- | ---- | ----------- |
| user | address | The address of the user |

| Name | Type | Description |
| ---- | ---- | ----------- |
| [0] | address | The claimer address |

### configureAssets

```solidity
function configureAssets(address[] assets, uint256[] emissionsPerSecond) external
```

Configure assets for a certain rewards emission

| Name | Type | Description |
| ---- | ---- | ----------- |
| assets | address[] | The assets to incentivize |
| emissionsPerSecond | uint256[] | The emission for each asset |

### handleAction

```solidity
function handleAction(address asset, uint256 userBalance, uint256 totalSupply) external
```

Called by the corresponding asset on any update that affects the rewards distribution

| Name | Type | Description |
| ---- | ---- | ----------- |
| asset | address | The address of the user |
| userBalance | uint256 | The balance of the user of the asset in the pool |
| totalSupply | uint256 | The total supply of the asset in the pool |

### getRewardsBalance

```solidity
function getRewardsBalance(address[] assets, address user) external view returns (uint256)
```

Returns the total of rewards of a user, already accrued + not yet accrued

| Name | Type | Description |
| ---- | ---- | ----------- |
| assets | address[] | The assets to accumulate rewards for |
| user | address | The address of the user |

| Name | Type | Description |
| ---- | ---- | ----------- |
| [0] | uint256 | The rewards |

### claimRewards

```solidity
function claimRewards(address[] assets, uint256 amount, address to) external returns (uint256)
```

Claims reward for a user, on the assets of the pool, accumulating the pending rewards

| Name | Type | Description |
| ---- | ---- | ----------- |
| assets | address[] | The assets to accumulate rewards for |
| amount | uint256 | Amount of rewards to claim |
| to | address | Address that will be receiving the rewards |

| Name | Type | Description |
| ---- | ---- | ----------- |
| [0] | uint256 | Rewards claimed |

### claimRewardsOnBehalf

```solidity
function claimRewardsOnBehalf(address[] assets, uint256 amount, address user, address to) external returns (uint256)
```

Claims reward for a user on its behalf, on the assets of the pool, accumulating the pending rewards.

_The caller must be whitelisted via &quot;allowClaimOnBehalf&quot; function by the RewardsAdmin role manager_

| Name | Type | Description |
| ---- | ---- | ----------- |
| assets | address[] | The assets to accumulate rewards for |
| amount | uint256 | The amount of rewards to claim |
| user | address | The address to check and claim rewards |
| to | address | The address that will be receiving the rewards |

| Name | Type | Description |
| ---- | ---- | ----------- |
| [0] | uint256 | The amount of rewards claimed |

### getUserUnclaimedRewards

```solidity
function getUserUnclaimedRewards(address user) external view returns (uint256)
```

Returns the unclaimed rewards of the user

| Name | Type | Description |
| ---- | ---- | ----------- |
| user | address | The address of the user |

| Name | Type | Description |
| ---- | ---- | ----------- |
| [0] | uint256 | The unclaimed user rewards |

### getUserAssetData

```solidity
function getUserAssetData(address user, address asset) external view returns (uint256)
```

Returns the user index for a specific asset

| Name | Type | Description |
| ---- | ---- | ----------- |
| user | address | The address of the user |
| asset | address | The asset to incentivize |

| Name | Type | Description |
| ---- | ---- | ----------- |
| [0] | uint256 | The user index for the asset |

### REWARD_TOKEN

```solidity
function REWARD_TOKEN() external view returns (address)
```

for backward compatibility with previous implementation of the Incentives controller

| Name | Type | Description |
| ---- | ---- | ----------- |
| [0] | address | The address of the reward token |

### PRECISION

```solidity
function PRECISION() external view returns (uint8)
```

for backward compatibility with previous implementation of the Incentives controller

| Name | Type | Description |
| ---- | ---- | ----------- |
| [0] | uint8 | The precision used in the incentives controller |

### DISTRIBUTION_END

```solidity
function DISTRIBUTION_END() external view returns (uint256)
```

_Gets the distribution end timestamp of the emissions_

