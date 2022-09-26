const main = async () => {
  const gameContractFactory = await hre.ethers.getContractFactory("MyEpicGame");
  const gameContract = await gameContractFactory.deploy(
    ["Galileu", "Pato Donald", "Galo Sniper"],
        [
            "https://i.imgur.com/HMH8HUu.jpeg",
            "https://i.imgur.com/7jdUohK.jpeg",
            "https://i.imgur.com/OkDeOz5.jpeg",
        ],
    [100, 900, 650], // HP values
    [3000, 25, 375], // Mana values
    [300, 450, 625], // Attack damage values
    "Plug Diferente",
    "https://i.imgur.com/GaKvHZh.jpeg",
     10000,
     50
  );

  await gameContract.deployed();
  console.log("Contrato implantado no endereço:", gameContract.address);

  let txn;
  
  txn = await gameContract.mintCharacterNFT(2);
  await txn.wait();
  console.log("Mint de NFT realizado.");

  txn = await gameContract.attackBoss();
  await txn.wait();

  txn = await gameContract.attackBoss();
  await txn.wait();
       
  console.log("Fim do deploy e mint!");

};

const runMain = async () => {
  try {
    await main();
    process.exit(0);
  } catch (error) {
    console.log(error);
    process.exit(1);
  }
};

runMain();