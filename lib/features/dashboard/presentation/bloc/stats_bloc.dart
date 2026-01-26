import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../../../core/services/statistics_service.dart';

// Events
abstract class StatsEvent extends Equatable {
  const StatsEvent();

  @override
  List<Object?> get props => [];
}

class StatsLoadRequested extends StatsEvent {
  final String userId;
  final DateTime? weekStart;

  const StatsLoadRequested(this.userId, {this.weekStart});

  @override
  List<Object?> get props => [userId, weekStart];
}

// States
abstract class StatsState extends Equatable {
  const StatsState();

  @override
  List<Object?> get props => [];
}

class StatsInitial extends StatsState {}

class StatsLoading extends StatsState {}

class StatsLoaded extends StatsState {
  final List<DailyStats> weeklyStats;
  final OverallStats overallStats;

  const StatsLoaded({
    required this.weeklyStats,
    required this.overallStats,
  });

  @override
  List<Object?> get props => [weeklyStats, overallStats];
}

class StatsError extends StatsState {
  final String message;

  const StatsError(this.message);

  @override
  List<Object?> get props => [message];
}

// BLoC
class StatsBloc extends Bloc<StatsEvent, StatsState> {
  final StatisticsService _statisticsService;

  StatsBloc({required StatisticsService statisticsService})
      : _statisticsService = statisticsService,
        super(StatsInitial()) {
    on<StatsLoadRequested>(_onLoadRequested);
  }

  Future<void> _onLoadRequested(
    StatsLoadRequested event,
    Emitter<StatsState> emit,
  ) async {
    emit(StatsLoading());
    try {
      final weekStart = event.weekStart ?? _getWeekStart(DateTime.now());
      final weeklyStats = await _statisticsService.calculateWeeklyStats(
        event.userId,
        weekStart,
      );
      final overallStats = await _statisticsService.calculateOverallStats(
        event.userId,
      );

      emit(StatsLoaded(
        weeklyStats: weeklyStats,
        overallStats: overallStats,
      ));
    } catch (e) {
      emit(StatsError('Erro ao carregar estatísticas: ${e.toString()}'));
    }
  }

  DateTime _getWeekStart(DateTime date) {
    final weekday = date.weekday;
    return DateTime(date.year, date.month, date.day)
        .subtract(Duration(days: weekday - 1));
  }
}
