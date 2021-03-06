import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:kyc3/app/app.dart';
import 'package:kyc3/models/models.dart';
import 'package:kyc3/services/services.dart';
import 'package:kyc3/utils/heavy_tasks.dart';
import 'package:kyc3/widgets/widgets.dart';
import 'package:web3dart/crypto.dart';

import '../widgets/item_words.dart';

enum _ImportType { privateKey, mnemonics }

class AlreadyHaveKeywordsScreen extends StatefulWidget {
  const AlreadyHaveKeywordsScreen({Key? key}) : super(key: key);

  @override
  _AlreadyHaveKeywordsScreenState createState() => _AlreadyHaveKeywordsScreenState();
}

class _AlreadyHaveKeywordsScreenState extends State<AlreadyHaveKeywordsScreen> {
  /// Type of import user can select from

  _ImportType? _importType;
  String? pvKey;
  List<CommonModel> phraseList = [];
  var tcPhrase = TextEditingController();
  var fcPhrase = FocusNode();

  var tcPrivateKey = TextEditingController();
  var fcPrivateKey = FocusNode();

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance!.addPostFrameCallback((timestamp) async {
      final result = await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) {
          return const _SelectImportTypeDialog();
        },
      );
      if (result != null) {
        _importType = result;
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    super.dispose();
    tcPrivateKey.dispose();
    fcPrivateKey.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isPrivateKey = _importType == _ImportType.privateKey;
    return BaseScaffold(
      appBarColor: Theme.of(context).backgroundColor,
      title: Strings.importWallet,
      actions: [
        if (_importType == _ImportType.mnemonics)
          Padding(
            padding: p20,
            child: Texts(
              "${phraseList.length}/24",
              style: Theme.of(context).textTheme.subtitle1?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ),
      ],
      child: _importType == null
          ? const SizedBox()
          : CustomScrollView(
              physics: const NeverScrollableScrollPhysics(),
              slivers: [
                SliverFillRemaining(
                  hasScrollBody: true,
                  child: Column(
                    children: [
                      Expanded(
                        child: ListView(
                          padding: p20.copyWith(top: 5.0),
                          children: [
                            Padding(
                              padding: const EdgeInsets.only(bottom: 20.0),
                              child: Texts(
                                isPrivateKey
                                    ? Strings.alreadyHaveKeywordsVerificationMsgPrivateKey
                                    : Strings.alreadyHaveKeywordsVerificationMsgMnemonics,
                                fontSize: 15.0,
                                color: Theme.of(context).colorScheme.secondaryVariant,
                                textAlign: TextAlign.center,
                              ),
                            ),
                            if (!isPrivateKey) _suggestionsTextField(),
                            if (!isPrivateKey) _selectedPhrasesGridView(),
                            if (isPrivateKey) _privateKeyTextField()
                          ],
                        ),
                      ),
                      _submitButton(),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  Widget _privateKeyTextField() {
    return TextFormFieldWidget(
      focusNode: fcPrivateKey,
      controller: tcPrivateKey,
      label: Strings.enterPrivateKey,
      textInputAction: TextInputAction.done,
      textInputType: TextInputType.visiblePassword,
      autoCorrect: false,
      enableSuggestions: false,
      maxLines: 3,
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(30),
        borderSide: BorderSide(color: Theme.of(context).primaryColor),
      ),
    );
  }

  Widget _suggestionsTextField() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20.0),
      child: Autocomplete<CommonModel>(
        optionsBuilder: (value) => getWordsSuggestions(value.text),
        displayStringForOption: (option) => option.name!,
        fieldViewBuilder: (_, controller, focusNode, onFieldSubmitted) {
          fcPhrase = focusNode;
          tcPhrase = controller;
          return TextFormFieldWidget(
            maxLength: 8,
            focusNode: focusNode,
            controller: controller,
            label: Strings.search,
            textInputType: TextInputType.name,
            textInputAction: TextInputAction.done,
            onFieldSubmitted: (value) => addPhrase(
              value,
              focusNode: focusNode,
              controller: controller,
            ),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp("[a-z]")),
            ],
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(30),
              borderSide: BorderSide(color: Theme.of(context).primaryColor),
            ),
          );
        },
        onSelected: (selected) => addPhrase(
          selected.name!,
          focusNode: fcPhrase,
          controller: tcPhrase,
        ),
        optionsViewBuilder: (_, onSelected, options) {
          return Align(
            alignment: Alignment.topLeft,
            child: Material(
              color: !prefs.isDark() ? Colors.grey[300] : Colors.grey[850],
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30.0)),
              child: SizedBox(
                width: screenWidth - 40.0,
                child: ListView.builder(
                  padding: const EdgeInsets.all(10.0),
                  itemCount: options.length,
                  itemBuilder: (context, index) {
                    final option = options.elementAt(index);
                    return ListTile(
                      onTap: () => onSelected(option),
                      title: Texts(option.name!),
                    );
                  },
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _selectedPhrasesGridView() {
    return Container(
      constraints: BoxConstraints(
        minHeight: screenHeight * .22,
      ),
      decoration: BoxDecoration(
        color: context.homeBackgroundColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Theme.of(context).primaryColor),
      ),
      child: Center(
        child: ScrollConfiguration(
          behavior: const NoGlowingBehavior(),
          child: GridView.count(
            shrinkWrap: true,
            crossAxisCount: 3,
            childAspectRatio: 4 / 1.5,
            mainAxisSpacing: 12.0,
            crossAxisSpacing: 12.0,
            physics: const NeverScrollableScrollPhysics(),
            padding: p16,
            children: phraseList
                .mapIndexed((index, word) => ItemWords(
                      word: word,
                      visible: true,
                      invisible: false,
                      textColor: Colors.white,
                      color: Theme.of(context).primaryColor,
                      onTap: () {},
                    ))
                .toList(),
          ),
        ),
      ),
    );
  }

  Widget _submitButton() {
    const double _buttonSize = 75.0;
    return AnimatedSize(
      duration: const Duration(milliseconds: 200),
      child: SizedBox(
        height: MediaQuery.of(context).viewInsets.bottom != 0.0 ? 0.0 : _buttonSize,
        child: Padding(
          padding: const EdgeInsets.only(left: 20.0, right: 20.0, bottom: 20.0, top: 8.0),
          child: FilledButton(
            onTap: submit,
            text: Strings.submit,
          ),
        ),
      ),
    );
  }

  void addPhrase(
    String phrase, {
    FocusNode? focusNode,
    TextEditingController? controller,
  }) {
    final kPhrase = phrase.trim().removeSpaces();

    if (kPhrase.isNotEmpty) {
      if (phraseList.length == 24) {
        showBotToastNotification(
          Strings.maxKeyPhraseError,
          textColor: Colors.white,
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 5),
        );
        return;
      }

      final isExist = phraseList.any((element) => element.name == kPhrase);

      if (isExist) {
        showBotToastNotification(
          Strings.keyPhraseAlreadyExists,
          textColor: Colors.white,
          backgroundColor: Colors.red,
        );
        return;
      }

      phraseList.add(CommonModel(name: kPhrase));
      controller!.clear();
      focusNode!.unfocus();
      setState(() {});
    }
  }

  void submit() async {
    if (_importType == _ImportType.mnemonics) {
      if (phraseList.length != 24) {
        showErrorSnackbar(Strings.invalidMnemonics);
      } else {
        verifyAccount(mnemonics: phraseList.toMnemonics());
      }
    } else {
      final pk = tcPrivateKey.text.trim();
      if (pk.isEmptyORNull) {
        showErrorSnackbar(Strings.pleaseEnterPvKey);
        return;
      }

      verifyAccount(pvKey: pk);
    }
  }

  void verifyAccount({String? pvKey, String? mnemonics}) async {
    CryptoAccount? account;

    if (pvKey != null) {
      account = web3Service.getUserCryptoAccount(strip0x(pvKey.trim()));
    }

    if (mnemonics != null) {
      account = web3Service.getCryptoAccountFromMnemonics(mnemonics);
    }

    if (account != null) {
      /// On Success will goto main screen otherwise
      /// Error has been handled in below methods directly
      final didSave = await safeStorage.savePrivateKey(
        account.privateKey!,
        cancelText: Strings.usePin,
        onUsePin: () {
          showLog("onUsePin");
          createPin(account!, isUsePin: true);
        },
        errorHwUnavailable: () {
          showLog("errorHwUnavailable");
          createPin(account!);
        },
        errorNoHardware: () {
          showLog("errorNoHardware");
          createPin(account!);
        },
        statusUnknown: () {
          showLog("statusUnknown");
          createPin(account!);
        },
        errorNoBiometricEnrolled: () async {
          showLog("errorNoBiometricEnrolled");
          createPin(account!);
        },
      );

      if (didSave == true) {
        prefs.setAuthType(Keys.bio);
        signUpUserOnServer(account);
      }
    } else {
      showErrorDialog(
        title: Strings.accountNotFound,
        description: pvKey != null ? Strings.accountNotFoundPvKeyMSG : Strings.accountNotFoundMnemonicsMSG,
      );
    }
  }

  void createPin(CryptoAccount account, {bool isUsePin = false}) async {
    if (!isUsePin) {
      final result = await showErrorDialog(
        title: Strings.authenticationFailed,
        description: Strings.errorMsgAuthFailed,
        okText: Strings.usePin,
      );
    }

    /// create new pin here
    final response = await navUtils.gotoCreateOrChangePinScreen();

    if (response == true) {
      prefs.setAuthType(Keys.pin);
      signUpUserOnServer(account);
    }
  }

  void signUpUserOnServer(CryptoAccount account) async {
    /// Save in secure storage also because if user has bio metrics enrolled
    /// while sign up and if user removes it later on we wont be able to
    /// retrieve user's private key from bio storage instead we have to use
    /// secure storage as a backup private key for user's account retrieval
    /// when user restarts the application.
    await secureStorage.savePrivateKey(account.privateKey!);

    /// login user to server here
    /// Assign imported account as user's current crypto account into app.
    cryptoAccount = account;
    showLoader();
    anonymousReceiveService.isNewUser = true;
    anonymousSendService.sendExchangeKeyRequest();
  }
}

class _SelectImportTypeDialog extends StatelessWidget {
  const _SelectImportTypeDialog({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text(Strings.selectImportType),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          h16,
          _getWidget(
            title: Strings.usingPvKey,
            onTap: () {
              Navigator.of(context).pop(_ImportType.privateKey);
            },
          ),
          h16,
          _getWidget(
            title: Strings.usingMnemonics,
            onTap: () {
              Navigator.of(context).pop(_ImportType.mnemonics);
            },
          ),
        ],
      ),
    );
  }

  Widget _getWidget({required String title, required VoidCallback onTap}) {
    return FilledButton(onTap: onTap, text: title);
  }
}
