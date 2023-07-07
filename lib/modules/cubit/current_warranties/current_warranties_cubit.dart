import 'package:autoequal/autoequal.dart';
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:warranty_keeper/data/interfaces/iwarranties_source.dart';
import 'package:warranty_keeper/data/models/user.dart';
import 'package:warranty_keeper/presentation/new_warranties/domain/entities/warranty_info.dart';
import 'package:copy_with_extension/copy_with_extension.dart';

part 'current_warranties_state.dart';
part 'current_warranties_cubit.g.dart';

// import 'firebase';

class CurrentWarrantiesCubit extends Cubit<CurrentWarrantiesState> {
  CurrentWarrantiesCubit({
    required this.warrantiesSource,
  }) : super(const _Loading());
  final IWarrantiesSource warrantiesSource;

  @override
  void emit(CurrentWarrantiesState state) async {
    final list = await warrantiesSource.getWarranties();

    emit(
      _Ready(
        warrantyInfo: list,
        expiring: getExpiringList(),
        remove: false,
      ),
    );
    super.emit(state);
  }

  getExpiringList() {
    List<WarrantyInfo> expiringList;
    expiringList = List.from(state.asReady.warrantyInfo);
    if (expiringList.any((e) => e.lifeTime)) {
      expiringList.removeWhere((ee) => ee.lifeTime);
    }

    if (expiringList.any((e) => e.endOfWarranty!.difference(DateTime.now()).inDays < 30)) {
      expiringList.removeWhere((ee) => ee.endOfWarranty!.difference(DateTime.now()).inDays > 30 || ee.lifeTime);

      expiringList.sort(
        ((a, b) => a.endOfWarranty!.compareTo(b.endOfWarranty!)),
      );
      emit(
        state.asReady.copyWith(
          expiring: expiringList,
        ),
      );
    }
    return expiringList;
  }

  void addOrEditWarranty({required WarrantyInfo warrantyInfo, required User user}) async {
    List<WarrantyInfo> expiringList;

    expiringList = List.from(state.asReady.warrantyInfo);

    if (expiringList.any((e) => e.warrantyId == warrantyInfo.warrantyId)) {
      expiringList[state.asReady.warrantyInfo.indexWhere((e) => e.warrantyId == warrantyInfo.warrantyId)] = warrantyInfo;
      emit(
        state.asReady.copyWith(
          remove: false,
          warrantyInfo: expiringList,
        ),
      );
    } else {
      expiringList.add(warrantyInfo);
    }
    getExpiringList();

    List<WarrantyInfo> newList;
    newList = List.from(state.asReady.warrantyInfo);
    getExpiringList();

    if (newList.any((e) => e.warrantyId == warrantyInfo.warrantyId)) {
      newList[state.asReady.warrantyInfo.indexWhere((e) => e.warrantyId == warrantyInfo.warrantyId)] = warrantyInfo;
      emit(
        state.asReady.copyWith(
          remove: false,
          warrantyInfo: newList,
        ),
      );
    } else {
      newList.add(warrantyInfo);

      emit(
        state.asReady.copyWith(
          remove: !state.asReady.remove,
          warrantyInfo: newList,
        ),
      );
    }
  }

  void removeWarranty(int index) {
    List<WarrantyInfo> removeList;
    removeList = state.asReady.warrantyInfo;
    removeList.removeAt(index);
    emit(
      state.asReady.copyWith(
        remove: !state.asReady.remove,
        warrantyInfo: removeList,
      ),
    );
  }
}
