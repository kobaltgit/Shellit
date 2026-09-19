/// Core Foundation library for Shellit SSH Client.
/// Exports domain models, entities, error failures, Result types, and interface contracts.
library core_foundation;

// Common utilities & types
export 'src/common/result.dart';
export 'src/common/failures.dart';
export 'src/common/logger.dart';
export 'src/common/ansi_utils.dart';

// Domain Enums
export 'src/domain/enums/enums.dart';

// Domain Entities
export 'src/domain/entities/host_entity.dart';
export 'src/domain/entities/key_entity.dart';
export 'src/domain/entities/folder_entity.dart';
export 'src/domain/entities/snippet_entity.dart';
export 'src/domain/entities/vault_settings_entity.dart';
export 'src/domain/entities/session_recording_entity.dart';
export 'src/domain/entities/ai_models.dart';

// Interface Contracts (Contract-First Design)
export 'src/interfaces/storage_interfaces.dart';
export 'src/interfaces/network_interfaces.dart';
export 'src/interfaces/plugin_interfaces.dart';
export 'src/interfaces/session_recorder_interface.dart';
export 'src/interfaces/localization_interfaces.dart';
