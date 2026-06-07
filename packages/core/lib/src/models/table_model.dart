import 'package:equatable/equatable.dart';
import 'package:rayssa_core/src/enums/table_status.dart';

class TableModel extends Equatable {
  const TableModel({
    required this.id,
    required this.number,
    required this.name,
    required this.status,
    this.currentSessionId,
    this.currentTotal = 0,
    this.openedAt,
    this.updatedAt,
  });

  final String id;
  final int number;
  final String name;
  final TableStatus status;
  final String? currentSessionId;
  final double currentTotal;
  final DateTime? openedAt;
  final DateTime? updatedAt;

  factory TableModel.fallback(int number) {
    return TableModel(
      id: 'mesa-$number',
      number: number,
      name: 'Mesa $number',
      status: TableStatus.free,
    );
  }

  factory TableModel.fromFirestore(String id, Map<String, dynamic> data) {
    return TableModel(
      id: id,
      number: (data['number'] as num?)?.toInt() ?? _numberFromId(id),
      name: data['name'] as String? ?? 'Mesa ${_numberFromId(id)}',
      status: TableStatus.fromString(data['status'] as String?),
      currentSessionId: data['currentSessionId'] as String?,
      currentTotal: (data['currentTotal'] as num?)?.toDouble() ?? 0,
      openedAt: _timestampToDate(data['openedAt']),
      updatedAt: _timestampToDate(data['updatedAt']),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'number': number,
      'name': name,
      'status': status.value,
      'currentSessionId': currentSessionId,
      'currentTotal': currentTotal,
      'openedAt': openedAt,
      'updatedAt': updatedAt,
    };
  }

  TableModel copyWith({
    String? id,
    int? number,
    String? name,
    TableStatus? status,
    String? currentSessionId,
    double? currentTotal,
    DateTime? openedAt,
    DateTime? updatedAt,
  }) {
    return TableModel(
      id: id ?? this.id,
      number: number ?? this.number,
      name: name ?? this.name,
      status: status ?? this.status,
      currentSessionId: currentSessionId ?? this.currentSessionId,
      currentTotal: currentTotal ?? this.currentTotal,
      openedAt: openedAt ?? this.openedAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
    id,
    number,
    name,
    status,
    currentSessionId,
    currentTotal,
    openedAt,
    updatedAt,
  ];
}

const defaultTableCount = 10;

List<TableModel> defaultTables({int count = defaultTableCount}) {
  return List.generate(count, (index) => TableModel.fallback(index + 1));
}

List<TableModel> mergeWithDefaultTables(
  Iterable<TableModel> firestoreTables, {
  int count = defaultTableCount,
}) {
  final tablesByNumber = <int, TableModel>{};

  for (final table in firestoreTables) {
    if (table.number < 1 || table.number > count) continue;
    tablesByNumber[table.number] = table;
  }

  return List.generate(count, (index) {
    final number = index + 1;
    return tablesByNumber[number] ?? TableModel.fallback(number);
  });
}

int _numberFromId(String id) {
  final match = RegExp(r'\d+').firstMatch(id);
  return int.tryParse(match?.group(0) ?? '') ?? 0;
}

DateTime? _timestampToDate(dynamic value) {
  if (value == null) return null;
  if (value is DateTime) return value;
  return value.toDate() as DateTime;
}
