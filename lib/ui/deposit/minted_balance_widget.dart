import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kyc3/app/app.dart';
import 'package:kyc3/cubits/balance/balance_cubit.dart';
import 'package:kyc3/widgets/widgets.dart';

class MintedBalanceWidget extends StatefulWidget {
  const MintedBalanceWidget({Key? key}) : super(key: key);

  @override
  State<MintedBalanceWidget> createState() => _MintedBalanceWidgetState();
}

class _MintedBalanceWidgetState extends State<MintedBalanceWidget> {
  Future<List<dynamic>?>? _future;

  @override
  void initState() {
    super.initState();
    _future = context.read<BalanceCubit>().checkAllMintedTokenBalance();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        BlocConsumer<BalanceCubit, BalanceState>(
          listener: (context, state) {
            if (state.status == BalanceCubitState.requestBalance) {
              setState(() {
                _future = context.read<BalanceCubit>().checkAllMintedTokenBalance();
              });
            }
          },
          builder: (context, state) {
            return FutureBuilder<List<dynamic>?>(
              future: _future,
              builder: (context, snapshot) {
                if (snapshot.hasData) {
                  final balance = snapshot.data?[0] ?? 0.0;
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20.0),
                    child: Texts(
                      balance.toString(),
                      textAlign: TextAlign.center,
                      fontSize: 20.0,
                      fontWeight: FontWeight.bold,
                    ),
                  );
                } else if (snapshot.hasError) {
                  return const Icon(Icons.error_outline);
                } else {
                  return const NativeLoader(scale: 0.8);
                }
              },
            );
          },
        ),
        Texts(
          " ${Strings.currentMintBalance}".toUpperCase(),
          textAlign: TextAlign.center,
          style: context.textTheme.bodyText2?.copyWith(fontSize: 12.0),
        ),
      ],
    );
  }
}
