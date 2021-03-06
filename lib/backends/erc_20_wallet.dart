import 'dart:convert';
import 'dart:math';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:kryptonia/backends/encrypt.dart';
import 'package:kryptonia/backends/mysql/sql_activities.dart';
import 'package:kryptonia/helpers/strings.dart';
import 'package:web3dart/web3dart.dart';

abstract class BaseERC20WalletAd {
  clientsInit(String unit);
  Future<Map?> createErcWallet();
  Future<String?> getEthBnbWalletBalance(String targetAddress);
  Future<Map> transferEthBnbToken(
      String privateKey, String receiverAdd, double amount, bool isEth);

  Future<List?> getAccTokenHistory(String address, String unit, bool isEth);

  Future<String?> getGasBal(String sender, String receiver, double amount);

  //
  getEstimatedGas(String erc20url);
}

class ERC20WalletAd implements BaseERC20WalletAd {
  EncryptApp _encryptApp = EncryptApp();
  ActivitiesSql _activitiesSql = ActivitiesSql();

  http.Client? httpClient;
  Web3Client? ethClient;
  String? lastTransactionHash;

  @override
  Future<Map?> createErcWallet() async {
    String add;
    Map? erc20encryptedAdd;
    try {
      EthereumAddress _ethAdd;
      String privateKey = hexString(64);

      EthPrivateKey address = EthPrivateKey.fromHex(privateKey);
      _ethAdd = await address.extractAddress();
      add = _ethAdd.toString();
      print(add);

      erc20encryptedAdd = {
        'erc20_' + TRANSFERKEY: _encryptApp.appEncrypt(privateKey),
        'erc20_' + ADDRESS: _encryptApp.appEncrypt(add),
      };
    } catch (e) {
      print(e);
    }

    return erc20encryptedAdd;
  }

  @override
  clientsInit(String unit) {
    String rpc = unit == ETH ? eTHRPCURL : BSC_RPC_URL;

    //  BSC_RPC_URL;
    httpClient = http.Client();
    ethClient = Web3Client(rpc, httpClient!);
  }

  //! ETH BNB Wallet Balance

  @override
  Future<String?> getEthBnbWalletBalance(String targetAddress) async {
    String? balance;
    try {
      EthereumAddress address = EthereumAddress.fromHex(targetAddress);
      EtherAmount amount = await ethClient!.getBalance(address);
      BigInt bal = amount.getInWei;
      balance = ((bal / BigInt.from(pow(10, 18))).toStringAsFixed(4));
    } catch (e) {
      print(e);
    }
    return balance;
  }

  //! ETH BNB Token Transfer

  @override
  Future<Map> transferEthBnbToken(
      String privateKey, String receiverAdd, double amount, bool isEth) async {
    Map? result;

    try {
      final credentials = EthPrivateKey.fromHex(privateKey);

      String? hash;

      hash = await ethClient!.sendTransaction(
        credentials,
        Transaction(
          to: EthereumAddress.fromHex(receiverAdd),
          maxGas: 10 * pow(10, 5) as int,
          value: EtherAmount.inWei(BigInt.from(amount * pow(10, 18))),
        ),
        chainId: isEth ? 1 : 56,
      );

      result = {
        STATUS: true,
        HASH: hash,
      };
      _activitiesSql.storeUserActivitiesSql(4);

      return result;
    } catch (e) {
      print(e);
      result = {
        STATUS: false,
        HASH: null,
      };

      return result;
    }
  }

  @override
  Future<String?> getGasBal(
      String sender, String receiver, double amount) async {
    String? gasPrice;
    try {
      BigInt gasPriceLimit = await ethClient!.estimateGas(
        sender: EthereumAddress.fromHex(sender),
        to: EthereumAddress.fromHex(receiver),
        value: EtherAmount.inWei(BigInt.from(amount * pow(10, 18))),
      );
      gasPrice = ((gasPriceLimit / BigInt.from(pow(10, 8))).toString());

      return gasPrice;
    } catch (e) {
      print(e);
    }
    return gasPrice;
  }

  @override
  Future<List> getAccTokenHistory(
      String address, String unit, bool isEth) async {
    List historyList = [];
    http.Response _response;
    String erc20url = isEth ? ETH_URL : BSC_URL;

    String? ethApi = dotenv.env['ETH_API'];
    String? bscApi = dotenv.env['BSC_API'];

    String? api = isEth ? ethApi : bscApi;

    String ethBnbUrl =
        "$erc20url/api?module=account&action=txlist&address=$address&page=1&offset=100&sort=desc&apikey=$api";

    try {
      _response = await http.get(Uri.parse(ethBnbUrl));
      var body = jsonDecode(_response.body);
      var result = body['result'];

      for (int index = 0; index < result.length; index++) {
        var date = int.parse(result[index][TIMESTAMP]);
        int timeMilli = date * 1000;
        String dateFormat = DateFormat.yMMMd()
            .format(DateTime.fromMillisecondsSinceEpoch(timeMilli));
        var amount =
            BigInt.parse(result[index][VALUE]) / BigInt.from(pow(10, 18));

        String to = result[index][TO].toString();

        bool income = to.toUpperCase() == address.toUpperCase() ? true : false;
        String hash = result[index][HASH];

        Map tokenHistory = {
          AMOUNT: amount.toStringAsFixed(4),
          UNIT: unit,
          DATETIME: dateFormat,
          INCOME: income,
          HASH: hash,
          TITLE: income ? BOUGHT : SOLD,
          DATA: result[index]
        };
        historyList.add(tokenHistory);
      }

      return historyList;
    } catch (e) {
      print(e);
    }
    return historyList;
  }

  @override
  getEstimatedGas(String erc20url) async {
    http.Response _response;
    String? bscApi = dotenv.env['BSC_API'];

    String? url =
        "$erc20url//api?module=proxy&action=eth_estimateGas&data=0x4e71d92d&to=0xEeee7341f206302f2216e39D715B96D8C6901A1C&value=0xff22&gasPrice=0x51da038cc&gas=0x5f5e0ff&apikey=$bscApi";
    try {
      _response = await http.get(Uri.parse(url));
      var body = jsonDecode(_response.body);
      var result = body['result'];
      var newRes = ((BigInt.parse(result)) / BigInt.from(pow(10, 18)));
      print(newRes);
    } catch (e) {
      print(e);
    }
  }
}
