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
    const LabFacetAbi=require("../artifacts/contracts/facets/LabFacet.sol/LabFacet.json").abi;
    const LabAccessControlFacetAbi=require("../artifacts/contracts/facets/LabAccessControlFacet.sol/LabAccessControlFacet.json").abi;
    const LabTokenDiamondAbi=require("../artifacts/hardhat-diamond-abi/HardhatDiamondABI.sol/LabTokenDiamond.json").abi; 

    const diamondContract = new ethers.Contract(diamondContractAddress, LabTokenDiamondAbi, provider.getSigner(signers[0]));
    const diamondLoupe = new ethers.Contract(diamondContractAddress, LoupeAbi, provider.getSigner(signers[0]));
    const labFacet = new ethers.Contract(diamondContractAddress, LabFacetAbi, provider.getSigner(signers[0]));
    const labAccessControlFacet = new ethers.Contract(diamondContractAddress, LabAccessControlFacetAbi, provider.getSigner(signers[0]));

    const labAccessControlFacets = [];
    const labFacets = [];
    const diamondContracts = [];
    
    console.log('Iniciando creación de owners, users y labs');
    for (let i = 0; i < 10; i++) {
      const signer = provider.getSigner(signers[i]);
      let contract = new ethers.Contract(diamondContractAddress, LabAccessControlFacetAbi, signer);
      labAccessControlFacets.push(contract);
      contract = new ethers.Contract(diamondContractAddress, LabFacetAbi, signer);
      labFacets.push(contract);
      contract = new ethers.Contract(diamondContractAddress, LabTokenDiamondAbi, signer);
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
        let lab = {
          id: 0,
          name: "Owner_" + name + "_Lab_" + j,
          info: "Info_" + j + "_" + name,
          url: "http://lab_" + j + "_" + name + ".example.com",
          owner: signers[i],
          price: generateRandomWeiValue(),
          labAvailableStart: generateRandomDate("2023-09-01", "2023-09-30"),
          labAvailableEnd: generateRandomDate("2024-08-01", "2024-08-30"),
        };
  
        result = await labFacets[i].addLab(
          lab.name,
          lab.url,
          lab.price,
          lab.labAvailableStart,
          lab.labAvailableEnd
        );
        
  
      }
      console.log("Owner ", i, " added");

    }

    result = await labAccessControlFacet.getLabOwners();
    console.log("Owners:", result.length);

    result = await labAccessControlFacet.getLabUsers();
    console.log("Users:", result.length);

    result = await labFacet.getAllLabs();
    console.log("Labs:", result.length);

    
}  

main().catch((error) => {
    console.error(error);
  });
  