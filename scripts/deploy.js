/* global ethers */
/* eslint prefer-const: "off" */

const { getSelectors, FacetCutAction } = require('./libraries/diamond.js')

async function deployDiamond () {
  const accounts = await ethers.getSigners()
  const contractOwner = accounts[0]

  // Deploy DiamondInit
  // DiamondInit provides a function that is called when the diamond is upgraded or deployed to initialize state variables
  // Read about how the diamondCut function works in the EIP2535 Diamonds standard
  const DiamondInit = await ethers.getContractFactory('DiamondInit')
  const diamondInit = await DiamondInit.deploy()
  await diamondInit.deployed()
  console.log('DiamondInit deployed:', diamondInit.address)

  // Deploy facets and set the `facetCuts` variable
  console.log('')
  console.log('Deploying facets')
  const FacetNames = [
    'DiamondCutFacet',
    'DiamondLoupeFacet',
    'OwnershipFacet'
  ]
  // The `facetCuts` variable is the FacetCut[] that contains the functions to add during diamond deployment
  const facetCuts = []
  for (const FacetName of FacetNames) {
    const Facet = await ethers.getContractFactory(FacetName)
    const facet = await Facet.deploy()
    await facet.deployed()
    console.log(`${FacetName} deployed: ${facet.address}`)
    facetCuts.push({
      facetAddress: facet.address,
      action: FacetCutAction.Add,
      functionSelectors: getSelectors(facet)
    })
  }

  // Creating a function call
  // This call gets executed during deployment and can also be executed in upgrades
  // It is executed with delegatecall on the DiamondInit address.
  let functionCall = diamondInit.interface.encodeFunctionData('init')

  // Setting arguments that will be used in the diamond constructor
  const diamondArgs = {
    owner: contractOwner.address,
    init: diamondInit.address,
    initCalldata: functionCall
  }

  // deploy Diamond
  const Diamond = await ethers.getContractFactory('Diamond')
  const diamond = await Diamond.deploy(facetCuts, diamondArgs)
  await diamond.deployed()
  console.log()
  console.log('Diamond deployed:', diamond.address)

  diamondCutFacet = await ethers.getContractAt('DiamondCutFacet', diamond.address)

  const myFacets = [];

//TreeLibrary -------------------------------------------------------------------
const TreeLibrary = await ethers.getContractFactory(
  "contracts/libraries/RivalIntervalTreeLibrary.sol:RivalIntervalTreeLibrary"
);
const treeLibrary = await TreeLibrary.deploy();
await treeLibrary.deployed();

console.log("TreeLibrary address:", treeLibrary.address);

//--------------------------------------------------------------------------------

//LibAccessControlEnumerable -------------------------------------------------------------------
const LibAccessControlEnumerable = await ethers.getContractFactory(
  "contracts/libraries/LibAccessControlEnumerable.sol:LibAccessControlEnumerable"
);
const libAccessControlEnumerable = await LibAccessControlEnumerable.deploy();
await libAccessControlEnumerable.deployed();

console.log("LibAccessControlEnumerable address:", libAccessControlEnumerable.address);

//--------------------------------------------------------------------------------


//TreeLibrary -------------------------------------------------------------------
const LibToken809 = await ethers.getContractFactory(
  "contracts/libraries/LibToken809.sol:LibToken809",{
    libraries: {
      RivalIntervalTreeLibrary: treeLibrary.address
  }}
);
const libToken809 = await LibToken809.deploy();
await libToken809.deployed();

console.log("LibToken809 address:", libToken809.address);

//--------------------------------------------------------------------------------

  const CPSFacet = await ethers.getContractFactory('CPSFacet',{
    libraries: {
      RivalIntervalTreeLibrary: treeLibrary.address,
      LibToken809: libToken809.address
  }});

  const cpsFacet = await CPSFacet.deploy()
  await cpsFacet.deployed()
  console.log("CPSFacet address:", cpsFacet.address);

  await cpsFacet.initialize('CPS809Token','LTK');



  let selectors = getSelectors(cpsFacet).remove(['supportsInterface(bytes4)'])

  myFacets.push({
    facetAddress: cpsFacet.address,
    action: FacetCutAction.Add,
    functionSelectors: selectors
  });

//---------
//CPSControlFacet
const CPSAccessControlFacet = await ethers.getContractFactory('CPSAccessControlFacet')
const cpsAccessControlFacet = await CPSAccessControlFacet.deploy()
await cpsAccessControlFacet.deployed()
console.log("CPSAccessControlFacet address:", cpsAccessControlFacet.address);

selectors = getSelectors(cpsAccessControlFacet).remove(['supportsInterface(bytes4)'])

myFacets.push({
  facetAddress: cpsAccessControlFacet.address,
  action: FacetCutAction.Add,
  functionSelectors: selectors
});

//-----------------

  tx = await diamondCutFacet.diamondCut(
    myFacets,
    ethers.constants.AddressZero, '0x')
  receipt = await tx.wait()
  if (!receipt.status) {
    throw Error(`Diamond upgrade failed: ${tx.hash}`)
  }

  let cpsAccessControl=await ethers.getContractAt('CPSAccessControlFacet', diamond.address);
  await cpsAccessControl.initialize('My','juanluis@melilla.uned.es','Spain');

  console.log('CPSFacets added to diamond')

  // returning the address of the diamond
  return diamond.address
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
if (require.main === module) {
  deployDiamond()
    .then(() => process.exit(0))
    .catch(error => {
      console.error(error)
      process.exit(1)
    })
}

exports.deployDiamond = deployDiamond
