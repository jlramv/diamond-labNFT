const { ethers } = require('ethers')

function generateRandomDate(start, end) {
  const startDate = new Date(start);
  startDate.setHours(0, 0, 0, 0);
  const endDate = new Date(end);
  endDate.setHours(0, 0, 0, 0);
  const randomTimestamp =
    Math.floor(Math.random() * (endDate.getTime() - startDate.getTime() + 1)) +
    startDate.getTime();
  return Math.floor(randomTimestamp); // Convertir a tiempo Unix (Linux timestamp)
}

function generateRandomEtherValue() {
  const minValue = ethers.utils.parseEther("0.001");
  const maxValue = ethers.utils.parseEther("0.009");
  const randomValue =
    Math.random() * maxValue.sub(minValue).toNumber() + minValue.toNumber();
  return randomValue;
}

function generateRandomWeiValue() {
  const minValue = ethers.utils.parseEther("0.001");
  const maxValue = ethers.utils.parseEther("0.009");
  const randomValue = ethers.BigNumber.from(
    Math.floor(
      Math.random() * maxValue.sub(minValue).toNumber() + minValue.toNumber()
    )
  );
  return randomValue;
}
async function main() {
    // Conectar a la red de prueba Hardhat
    const provider = new ethers.providers.JsonRpcProvider(
      "http://127.0.0.1:8545"
    );

    const signers = await provider.listAccounts();
 
    // Crear una instancia del contrato
    const diamondContractAddress = "0xDc64a140Aa3E981100a9becA4E685f962f0cF6C9";

    console.log("Diamond contract deployed at:", diamondContractAddress);
    const diamondAbi =
      require("../artifacts/contracts/Diamond.sol/Diamond.json").abi;

    const LoupeAbi=require("../artifacts/contracts/facets/DiamondLoupeFacet.sol/DiamondLoupeFacet.json").abi;
    const CPSFacetAbi=require("../artifacts/contracts/facets/CPSFacet.sol/CPSFacet.json").abi;
    const CPSAccessControlFacetAbi=require("../artifacts/contracts/facets/CPSAccessControlFacet.sol/CPSAccessControlFacet.json").abi;
    const CPSTokenDiamondAbi=require("../artifacts/hardhat-diamond-abi/HardhatDiamondABI.sol/CPSTokenDiamond.json").abi; 

    const diamondContract = new ethers.Contract(diamondContractAddress, CPSTokenDiamondAbi, provider.getSigner(signers[0]));
    const diamondLoupe = new ethers.Contract(diamondContractAddress, LoupeAbi, provider.getSigner(signers[0]));
    const cpsFacet = new ethers.Contract(diamondContractAddress, CPSFacetAbi, provider.getSigner(signers[0]));
    const cpsAccessControlFacet = new ethers.Contract(diamondContractAddress, CPSAccessControlFacetAbi, provider.getSigner(signers[0]));

    const cpsAccessControlFacets = [];
    const cpsFacets = [];
    const diamondContracts = [];
    
    console.log('Iniciando creación de owners, users y cpss');
    for (let i = 0; i < 10; i++) {
      const signer = provider.getSigner(signers[i]);
      let contract = new ethers.Contract(diamondContractAddress, CPSAccessControlFacetAbi, signer);
      cpsAccessControlFacets.push(contract);
      contract = new ethers.Contract(diamondContractAddress, CPSFacetAbi, signer);
      cpsFacets.push(contract);
      contract = new ethers.Contract(diamondContractAddress, CPSTokenDiamondAbi, signer);
      diamondContracts.push(contract);
    }
    
    let userIndex = 1;
    for (i = 1; i < 10; i++) {
      let name = signers[i].slice(-4);
  
      let owner = {
        name: "Owner_" + name,
        who: signers[i],
        contact: "Owner_" + name + "@example.com",
        country: "Spain",
      };
  
      
      let result = await diamondContract.addOwner(
        owner.name,
        owner.who,
        owner.contact,
        owner.country
      );
      
    //  console.log("Owner", owner.name, "added");

      let user = {
        name: "User " + userIndex,
        who: signers[userIndex + 10],
        owner: signers[i],
        contact: "user" + userIndex + "@example.com",
        country: "Canada",
        validityStart: 1693526400000,
        validityEnd: 1725062400000,
        balance: 0,
      };

      userIndex++;
      
      result = await diamondContracts[i].addAllowed(
        user.who,
        user.contact,
        user.validityStart,
        user.validityEnd
      );
   //   console.log("User", user.name, "added");

      for (let j = 1; j <= 5; j++) {
        let cps = {
          id: 0,
          name: "Owner_" + name + "_CPS_" + j,
          info: "Info_" + j + "_" + name,
          url: "http://cps_" + j + "_" + name + ".example.com",
          owner: signers[i],
          price: generateRandomWeiValue(),
          cpsAvaicpsleStart: generateRandomDate("2023-09-01", "2023-09-30"),
          cpsAvaicpsleEnd: generateRandomDate("2024-08-01", "2024-08-30"),
        };
  
        result = await cpsFacets[i].addCPS(
          cps.name,
          cps.url,
          cps.price,
          cps.cpsAvaicpsleStart,
          cps.cpsAvaicpsleEnd
        );
        
  
      }
      console.log("Owner ", i, " added");

    }

    result = await cpsAccessControlFacet.getCPSOwners();
    console.log("Owners:", result.length);

    result = await cpsAccessControlFacet.getCPSUsers();
    console.log("Users:", result.length);

    result = await cpsFacet.getAllCPSs();
    console.log("CPSs:", result.length);

    
}  

main().catch((error) => {
    console.error(error);
  });
  