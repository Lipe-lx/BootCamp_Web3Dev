//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

//##### SEÇÃO DE IMPORTAÇÕES #####// 

//Importar o contrato ERC721 (NFT) para herança
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
//Importar funçoes de ajuda do OpenZeppelin
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
//Hardhat
import "hardhat/console.sol";
//Biblioteca para codificar em Base64
import "./libraries/Base64.sol";

//##### CONTRATO #####// 

//is ERC721 -> herança para o contrato de ERC721(NFT)
contract MyEpicGame is ERC721 {
   
  //estruturação dos atributos de cada NFT
  struct CharacterAttributes {
    uint characterIndex;
    string name;
    string imageURI;
    uint hp;
    uint maxHp;
    uint mana;
    uint attackDamage;
  }

  //Criando um indentificador únido das NFTs -> tokenId
  //Incremento de +1 a cada mint // tokenId é a chave dos mapas de cada nft
  using Counters for Counters.Counter;
  Counters.Counter private _tokenIds;

  //Criacao de uma lista de array que tenha a estrutura (struct) dos NFTS (CharacterAttributes)
  //Instanciando em uma variavel para posterior utilização
  CharacterAttributes[] defaultCharacters;

  //Criacao de um mapa linkando o tokenId aos atributos das NFTs
  //Instanciando em uma variavel para posterior utilização
  mapping(uint256 => CharacterAttributes) public nftHolderAttributes;

  //Criacao de um mapa linkando o endreço de quem mintou ao tokenId
  mapping(address => uint256) public nftHolders;

  //Eventos criados para pegar no Dapp o mint consolidado da NFT e a finalizacao do ataque
  event CharacterNFTMinted(address sender, uint256 tokenId, uint256 characterIndex);
  event AttackComplete(uint newBossHp, uint newPlayerHp);

  //Criação da estrutura do BigBoss, o mesno estará somente no contrato, nao será NFT.
  struct BigBoss {
    string name;
    string imageURI;
    uint hp;
    uint maxHp;
    uint attackDamage;
  }
  //Instanciando em uma variavel para posterior utilização
  BigBoss public bigBoss;

  //constructor sera executado somente uma vez quando o contrato for criado
  //Ele faz a inicialização de variaveis de estado
  //Variáveis de estado são valores armazenados permanentemente na memória de contrato.
  constructor (
    string[] memory characterNames,
    string[] memory characterImageURIs,
    uint[] memory characterHp,
    uint[] memory characterMana,
    uint[] memory characterAttackDmg,
    string memory bossName, // Essas novas variáveis serão passadas via run.js ou deploy.js
    string memory bossImageURI,
    uint bossHp,
    uint bossAttackDamage
    // Embaixo, voce tambem pode ver um simbolo especial para identificar nossas NFTs
    // Esse eh o nome e o simbolo do nosso token, ex Ethereum ETH.
  )

  ERC721("LipeGame", "LPG")
    
  {
    // Inicializacao do boss. Salva na nossa variável global de estado "bigBoss".
    bigBoss = BigBoss({
      name: bossName,
      imageURI: bossImageURI,
      hp: bossHp,
      maxHp: bossHp,
      attackDamage: bossAttackDamage
    });
    console.log("Boss inicializado com sucesso %s com HP %s, img %s", bigBoss.name, bigBoss.hp, bigBoss.imageURI);
    
    //Criacao de um loop para alocar os atributos caracteristicos de cada NFT
    //Se o tamanho do nome for < 0 quer dizer que nao existe NFT para este id
    for(uint i = 0; i < characterNames.length; i += 1) {
      defaultCharacters.push(CharacterAttributes({
        characterIndex: i, //index dos atributos espessificos de cada NFT
        name: characterNames[i],
        imageURI: characterImageURIs[i],
        hp: characterHp[i],
        maxHp: characterHp[i],
        mana: characterMana[i],
        attackDamage: characterAttackDmg[i]
      }));
    
      //Instanciando uma variavel para posterior utilização e identificarmos no console a criacao dos NFTS (criacao != mint)
      // O uso do console.log() do hardhat nos permite 4 parametros em qualquer orden dos seguintes tipos: uint, string, bool, address
      CharacterAttributes memory c = defaultCharacters[i];
      console.log("Personagem inicializado: %s com %s de HP, img %s", c.name, c.hp, c.imageURI);
        
    }
    // Incremento no tokenIds para que minha primeira NFT tenha o ID 1.
    // No Solidity o numero 0 possui varias implicações, entao neste caso e bom uso evita-lo
    _tokenIds.increment();
  }
 
  //### MINTANDO ###// 

  //A proxima função faz o mint do nft tendo como parametro o _characterIndex
  //Os atributos das NFTS neste projeto sao mutaveis, portanto eh necessario vincular cada atributo ao seu NFT especifico 
  //_characterIndex é o index de cada atributo caracteristico da NFT específica
  function mintCharacterNFT(uint _characterIndex) external {
    // Instancia em uma variavel o tokenId atual (começa em 1 já que incrementamos no constructor).
    uint256 newItemId = _tokenIds.current();
      
    // A funcao magica! Atribui o tokenID (index da nossa NFT) para o endereço da carteira de quem chamou o contrato.
    _safeMint(msg.sender, newItemId);

    //nftHolderAttributes é uma mapa tokenId -> atributos (CharacterAttributes)
    //chamamos ele que está instanciado em newItemId, no caso o tokenId atual ".current()"
    nftHolderAttributes[newItemId] = CharacterAttributes({
      characterIndex: _characterIndex,
      name: defaultCharacters[_characterIndex].name,
      imageURI: defaultCharacters[_characterIndex].imageURI,
      hp: defaultCharacters[_characterIndex].hp,
      maxHp: defaultCharacters[_characterIndex].maxHp,
      mana: defaultCharacters[_characterIndex].mana,
      attackDamage: defaultCharacters[_characterIndex].attackDamage
    });
      
    //identificar no console o mint dos NFTS
    console.log("Mintou NFT c/ tokenId %s e characterIndex %s", newItemId, _characterIndex);

    //Criar um controle interno do contrato para gerenciar os enderecos que possuem NFTs
    //Mantem um jeito facil de ver quem possui a NFT
    nftHolders[msg.sender] = newItemId;

    //Incrementa +1 no tokenId para o mint da proxima NFT.
    _tokenIds.increment();

    //Evento para quando o NFT for mintado com sucesso
    emit CharacterNFTMinted(msg.sender, newItemId, _characterIndex);
  }

  //tokenURI -> é a url de direcionamento ao arquivo externo da NFT
  //O tokenURI tem um formato específico, na verdade! Na verdade, está esperando os dados NFT em JSON
  //O metodo de tokenURI mais utilizado hoje é enviando os dados ao IPFS e pegando o tokenURI=ipfs://CID
  //IPFS não utilizado neste projeto
  //função para tratar o tokenURI
  function tokenURI(uint256 _tokenId) public view override returns (string memory) {
  
    CharacterAttributes memory charAttributes = nftHolderAttributes[_tokenId];
  
    string memory strHp = Strings.toString(charAttributes.hp);
    string memory strMaxHp = Strings.toString(charAttributes.maxHp);
    string memory strMana = Strings.toString(charAttributes.mana);
    string memory strAttackDamage = Strings.toString(charAttributes.attackDamage);
  
    string memory json = Base64.encode(
      abi.encodePacked(
        '{"name": "',
        charAttributes.name,
        ' -- NFT #: ',
        Strings.toString(_tokenId),
        '", "description": "Esta NFT da acesso ao meu jogo NFT!", "image": "',
        charAttributes.imageURI,
        '", "attributes": [ { "trait_type": "Health Points", "value": ',strHp,', "max_value":',strMaxHp,'}, { "trait_type": "Mana Points", "value": ',
        strMana,'}, { "trait_type": "Attack Damage", "value": ',
        strAttackDamage,'} ]}'
      )
    );

    string memory output = string(
      abi.encodePacked("data:application/json;base64,", json)
    );

    return output;

  }

  // ###LOGICA DO BOSS### //

  //Funcao de ataque do Boss
  function attackBoss() public {
    // Pega o estado da NFT do jogador. nftHolders é um mapa address -> tokenId
    uint256 nftTokenIdOfPlayer = nftHolders[msg.sender];
    CharacterAttributes storage player = nftHolderAttributes[nftTokenIdOfPlayer];

    console.log("\nJogador com personagem %s ira atacar. Tem %s de HP e %s de PA", player.name, player.hp, player.attackDamage);
    console.log("Boss %s tem %s de HP e %s de PA", bigBoss.name, bigBoss.hp, bigBoss.attackDamage);

    // Checa se o hp do jogador é maior que 0.
    //require realiza uma verificação, dando certo executa o restante do codigo, dando errado envia uma mensagem
    require (
      player.hp > 0,
      "Erro: Seu personagem nao tem HP."
    );

    // Checa que o hp do boss é maior que 0.
    require (
      bigBoss.hp > 0,
      "Erro: Boss deve ter HP para ser atacado."
    );

    //Permite que o jogador ataque o boss.
    //Esta função no inicio e necessaria pois no type uint nao se aceita numeros negativos
    //Logo o nem o personagem nem o boss podem gerar danos negativos
    if (bigBoss.hp < player.attackDamage) {
      bigBoss.hp = 0;
    }
    else {
      bigBoss.hp = bigBoss.hp - player.attackDamage;
    }

    // Permite que o boss ataque o jogador.
    if (player.hp < bigBoss.attackDamage) {
      player.hp = 0;
    } 
    else {
      player.hp = player.hp - bigBoss.attackDamage;
    }

    console.log("Jogador atacou o boss. Boss ficou com HP: %s", bigBoss.hp);
    console.log("Boss atacou o jogador. Jogador ficou com hp: %s\n", player.hp);

    //Evento que  permite atualizar o HP do player e do boss dinamicamente sem recarregar a página. Parece um jogo real.
    emit AttackComplete(bigBoss.hp, player.hp);
  }

  //Construir função para checar se o usuário tem a NFT.
  function checkIfUserHasNFT() public view returns (CharacterAttributes memory) {
    // Pega o tokenId do personagem NFT do usuario
    uint256 userNftTokenId = nftHolders[msg.sender];
    // Se o usuario tiver um tokenId no map, retorne seu personagem
    if (userNftTokenId > 0) {
      return nftHolderAttributes[userNftTokenId];
    }
    // Senão, retorne um personagem vazio
    else {
      CharacterAttributes memory emptyStruct;
      return emptyStruct;
    }
  }

  //Funcao para recuperar os personagens padrão.
  function getAllDefaultCharacters() public view returns (CharacterAttributes[] memory) {
    return defaultCharacters;
  }

  //Funcao de recuperar o Boss
  function getBigBoss() public view returns (BigBoss memory) {
    return bigBoss;
  }
      
}

//ContratoTest 22-09-22 -> 0xe285ee27AF3Bec7C3497584Eb34c39A25Aa165AE