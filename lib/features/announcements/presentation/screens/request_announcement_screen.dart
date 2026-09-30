import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import '../providers/announcement_providers.dart';
import '../providers/lugar_fisico_providers.dart';
import 'package:gea_app/config/theme/app_tokens.dart';
import 'package:gea_app/core/presentation/widgets/gea_text_field.dart';
import 'package:gea_app/core/presentation/widgets/gea_button.dart';
import 'package:gea_app/features/auth/presentation/providers/auth_providers.dart';
import '../../domain/entities/announcement_request.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:gea_app/core/utils/image_utils.dart';

class RequestAnnouncementScreen extends ConsumerStatefulWidget {
  final AnnouncementRequest? editingRequest;
  const RequestAnnouncementScreen({super.key, this.editingRequest});

  @override
  ConsumerState<RequestAnnouncementScreen> createState() => _RequestAnnouncementScreenState();
}

class _RequestAnnouncementScreenState extends ConsumerState<RequestAnnouncementScreen> {
  final _formKey = GlobalKey<FormState>();

  // Text Controllers
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _correoContactoController = TextEditingController();
  final _responsableController = TextEditingController();

  // State Variables
  DateTime? _fechaInicio;
  DateTime? _fechaFin;
  TimeOfDay? _horaInicio;
  TimeOfDay? _horaFin;
  bool _requierePiezaGrafica = false;
  final List<int> _selectedLugares = [];
  File? _imageFile;
  Uint8List? _imageBytes;
  bool _hasInitializedUserData = false;

  @override
  void initState() {
    super.initState();
    final editing = widget.editingRequest;
    if (editing != null) {
      _titleController.text = editing.title;
      _descriptionController.text = editing.description;
      _correoContactoController.text = editing.correoContacto ?? '';
      _responsableController.text = editing.responsableAnuncio ?? '';
      _fechaInicio = editing.fechaInicioPublicacion;
      _fechaFin = editing.fechaFinPublicacion;
      _horaInicio = _parseTime(editing.horaInicio);
      _horaFin = _parseTime(editing.horaFin);
      _requierePiezaGrafica = editing.requierePiezaGrafica;
      _selectedLugares.addAll(editing.idsLugaresFisicos);
      _hasInitializedUserData = true;
    } else {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final authState = ref.read(authProvider);
        if (authState.user != null) {
          _responsableController.text = authState.user!.name;
          _correoContactoController.text = authState.user!.email;
        }
      });
    }
  }

  /// Convierte "HH:mm:ss" del backend en TimeOfDay. Null si no aplica.
  static TimeOfDay? _parseTime(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    final parts = raw.split(':');
    if (parts.length < 2) return null;
    final h = int.tryParse(parts[0]);
    final m = int.tryParse(parts[1]);
    if (h == null || m == null) return null;
    return TimeOfDay(hour: h, minute: m);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _correoContactoController.dispose();
    _responsableController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );
    if (image != null) {
      final bytes = await image.readAsBytes();
      setState(() {
        _imageFile = File(image.path);
        _imageBytes = bytes;
      });
    }
  }

  void _showLugaresModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (ctx) {
        return Consumer(
          builder: (context, modalRef, _) {
            final lugaresAsync = modalRef.watch(lugaresFisicosProvider);
            final bottomPadding = MediaQuery.of(context).padding.bottom;
            return Container(
              height: MediaQuery.of(context).size.height * 0.6,
              padding: EdgeInsets.fromLTRB(24, 24, 24, 24 + bottomPadding),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text('Seleccionar Lugares Físicos', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  Expanded(
                    child: lugaresAsync.when(
                      data: (lugares) {
                        if (lugares.isEmpty) return const Center(child: Text('No hay lugares disponibles'));
                        return StatefulBuilder(
                          builder: (context, setModalState) {
                            return ListView.builder(
                              itemCount: lugares.length,
                              itemBuilder: (context, index) {
                                final lugar = lugares[index];
                                final isSelected = _selectedLugares.contains(lugar.id);
                                return CheckboxListTile(
                                  title: Text(lugar.nombre),
                                  subtitle: Text(lugar.descripcion),
                                  value: isSelected,
                                  activeColor: Theme.of(context).primaryColor,
                                  onChanged: (val) {
                                    setModalState(() {
                                      if (val == true) {
                                        _selectedLugares.add(lugar.id);
                                      } else {
                                        _selectedLugares.remove(lugar.id);
                                      }
                                    });
                                    setState(() {}); // Update the parent screen
                                  },
                                );
                              },
                            );
                          },
                        );
                      },
                      loading: () => const Center(child: CircularProgressIndicator()),
                      error: (err, stack) => Center(child: Text('Error: $err')),
                    ),
                  ),
                  const SizedBox(height: 16),
                  GeaButton(text: 'Aceptar', onPressed: () => Navigator.pop(context)),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _onSubmit() async {
    if (_formKey.currentState!.validate()) {
      if (_fechaInicio == null || _fechaFin == null || _horaInicio == null || _horaFin == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Debes seleccionar las fechas y horas de publicación'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
        return;
      }

      if (_fechaFin!.isBefore(_fechaInicio!)) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('La fecha de fin no puede ser anterior a la de inicio'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
        return;
      }

      final editing = widget.editingRequest;
      final bool yaTienePieza =
          editing?.piezaGraficaUrl != null && editing!.piezaGraficaUrl!.isNotEmpty;

      if (!_requierePiezaGrafica && _imageFile == null && !yaTienePieza) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Por favor, selecciona una imagen para el anuncio'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
        return;
      }

      if (editing != null) {
        await ref.read(requestFormProvider.notifier).submitEdit(
              id: editing.id,
              title: _titleController.text.trim(),
              description: _descriptionController.text.trim(),
              category: editing.category,
              correoContacto: _correoContactoController.text.trim(),
              responsableAnuncio: _responsableController.text.trim(),
              fechaInicioPublicacion: _fechaInicio!,
              fechaFinPublicacion: _fechaFin!,
              horaInicio: _horaInicio!,
              horaFin: _horaFin!,
              requierePiezaGrafica: _requierePiezaGrafica,
              idsLugaresFisicos: _selectedLugares,
              existingPiezaGraficaUrl: editing.piezaGraficaUrl,
              imageFile: _imageFile,
            );
      } else {
        await ref.read(requestFormProvider.notifier).submitRequest(
              title: _titleController.text.trim(),
              description: _descriptionController.text.trim(),
              category: null,
              correoContacto: _correoContactoController.text.trim(),
              responsableAnuncio: _responsableController.text.trim(),
              fechaInicioPublicacion: _fechaInicio!,
              fechaFinPublicacion: _fechaFin!,
              horaInicio: _horaInicio!,
              horaFin: _horaFin!,
              requierePiezaGrafica: _requierePiezaGrafica,
              idsLugaresFisicos: _selectedLugares,
              imageFile: _imageFile,
            );
      }

      final state = ref.read(requestFormProvider);
      if (state.isSuccess) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(widget.editingRequest != null
                  ? 'Solicitud actualizada y reenviada'
                  : 'Solicitud enviada con éxito'),
              backgroundColor: Theme.of(context).colorScheme.primary,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
          );
          Navigator.pop(context);
        }
      } else if (state.errorMessage != null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.errorMessage!), 
              backgroundColor: Theme.of(context).colorScheme.error,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
          );
        }
      }
    }
  }

  Future<void> _selectDate(bool isStart) async {
    final DateTime minDate = DateTime.now().subtract(const Duration(days: 1));
    final DateTime maxDate = DateTime.now().add(const Duration(days: 365));
    DateTime candidate = isStart
        ? (_fechaInicio ?? DateTime.now())
        : (_fechaFin ?? _fechaInicio ?? DateTime.now());
    if (candidate.isBefore(minDate)) candidate = minDate;
    if (candidate.isAfter(maxDate)) candidate = maxDate;

    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: candidate,
      firstDate: minDate,
      lastDate: maxDate,
    );
    if (picked != null) {
      setState(() {
        if (isStart) {
          _fechaInicio = picked;
          if (_fechaFin != null && _fechaFin!.isBefore(_fechaInicio!)) {
            _fechaFin = null;
          }
        } else {
          _fechaFin = picked;
        }
      });
    }
  }

  Future<void> _selectTime(bool isStart) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: isStart ? (_horaInicio ?? TimeOfDay.now()) : (_horaFin ?? TimeOfDay.now()),
      builder: (BuildContext context, Widget? child) {
        return Localizations.override(
          context: context,
          locale: const Locale('en', 'US'),
          child: child,
        );
      },
    );
    if (picked != null) {
      setState(() {
        if (isStart) {
          _horaInicio = picked;
        } else {
          _horaFin = picked;
        }
      });
    }
  }

  String _formatTime(TimeOfDay time) {
    final int hour = time.hour == 0 ? 12 : (time.hour > 12 ? time.hour - 12 : time.hour);
    final String min = time.minute.toString().padLeft(2, '0');
    final String period = time.period == DayPeriod.am ? 'AM' : 'PM';
    return '$hour:$min $period';
  }

  Widget _buildDatePickerBox(String label, DateTime? date, VoidCallback onTap) {
    return _buildPickerBox(
      label, 
      date != null ? DateFormat('dd MMM yyyy', 'es_ES').format(date) : 'Seleccionar', 
      Icons.calendar_today_rounded, 
      onTap
    );
  }

  Widget _buildTimePickerBox(String label, TimeOfDay? time, VoidCallback onTap) {
    return _buildPickerBox(
      label, 
      time != null ? _formatTime(time) : 'Seleccionar', 
      Icons.access_time_rounded, 
      onTap
    );
  }

  Widget _buildPickerBox(String label, String value, IconData icon, VoidCallback onTap) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: theme.scaffoldBackgroundColor,
          border: Border.all(color: theme.dividerColor),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(fontSize: 12, color: AppTokens.textMuted)),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(icon, size: 16, color: AppTokens.textSecondary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    value,
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: AppTokens.textPrimary),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final formState = ref.watch(requestFormProvider);
    final authState = ref.watch(authProvider);
    final theme = Theme.of(context);

    if (authState.user != null && !_hasInitializedUserData) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!_hasInitializedUserData) {
          _responsableController.text = authState.user!.name;
          _correoContactoController.text = authState.user!.email;
          setState(() {
            _hasInitializedUserData = true;
          });
        }
      });
    }

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        appBar: AppBar(
          title: Text(widget.editingRequest != null ? 'Editar Solicitud' : 'Solicitar Anuncio'),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.only(left: 24, right: 24, top: 32, bottom: 100),
          child: Center(
            child: Container(
              constraints: const BoxConstraints(maxWidth: 600),
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: theme.dividerColor),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.02),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  )
                ],
              ),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text('Información General', style: theme.textTheme.titleLarge),
                    const SizedBox(height: 8),
                    Text(
                      'Completa todos los campos obligatorios para evitar que la solicitud sea rechazada por el administrador.',
                      style: theme.textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 32),
                    
                    GeaTextField(
                      label: 'Título del Anuncio *',
                      hint: 'Ej. Feria del Libro 2024',
                      controller: _titleController,
                      validator: (value) => value == null || value.isEmpty ? 'Requerido' : null,
                    ),
                    const SizedBox(height: 24),
                    const Text('Descripción *', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppTokens.textSecondary)),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _descriptionController,
                      decoration: InputDecoration(
                        hintText: 'Escribe los detalles aquí...',
                        filled: true,
                        fillColor: theme.scaffoldBackgroundColor,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: theme.dividerColor)),
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: theme.dividerColor)),
                      ),
                      maxLines: 4,
                      validator: (value) => (value == null || value.length < 10) ? 'Escribe al menos 10 caracteres' : null,
                    ),
                    const SizedBox(height: 24),

                    const Text('Lugares Físicos (Opcional)', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppTokens.textSecondary)),
                    const SizedBox(height: 8),
                    InkWell(
                      onTap: _showLugaresModal,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: theme.scaffoldBackgroundColor,
                          border: Border.all(color: theme.dividerColor),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                _selectedLugares.isEmpty 
                                  ? 'Añadir lugar...' 
                                  : '${_selectedLugares.length} lugares seleccionados',
                                style: const TextStyle(fontSize: 15, color: AppTokens.textPrimary),
                              ),
                            ),
                            const Icon(Icons.arrow_drop_down, color: AppTokens.textMuted),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),
                    
                    const Divider(),
                    const SizedBox(height: 32),
                    
                    Text('Contacto', style: theme.textTheme.titleLarge),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        Expanded(
                          child: GeaTextField(
                            label: 'Responsable *',
                            hint: 'Nombre completo',
                            controller: _responsableController,
                            validator: (value) => value == null || value.isEmpty ? 'Requerido' : null,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: GeaTextField(
                            label: 'Correo de Contacto *',
                            hint: 'correo@ejemplo.com',
                            controller: _correoContactoController,
                            readOnly: true,
                            keyboardType: TextInputType.emailAddress,
                            validator: (value) {
                              if (value == null || value.isEmpty) return 'Requerido';
                              if (!value.contains('@')) return 'Inválido';
                              return null;
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),
                    
                    const Divider(),
                    const SizedBox(height: 32),
                    
                    Text('Temporalidad', style: theme.textTheme.titleLarge),
                    const SizedBox(height: 24),
                    
                    Row(
                      children: [
                        Expanded(child: _buildDatePickerBox('Fecha Inicio', _fechaInicio, () => _selectDate(true))),
                        const SizedBox(width: 16),
                        Expanded(child: _buildDatePickerBox('Fecha Fin', _fechaFin, () => _selectDate(false))),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(child: _buildTimePickerBox('Hora Inicio', _horaInicio, () => _selectTime(true))),
                        const SizedBox(width: 16),
                        Expanded(child: _buildTimePickerBox('Hora Fin', _horaFin, () => _selectTime(false))),
                      ],
                    ),
                    const SizedBox(height: 32),
                    
                    const Divider(),
                    const SizedBox(height: 24),
                    
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Pieza Gráfica', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppTokens.textPrimary)),
                              SizedBox(height: 4),
                              Text('¿El anuncio requiere diseño por parte del equipo?', style: TextStyle(fontSize: 13, color: AppTokens.textMuted)),
                            ],
                          ),
                        ),
                        Switch(
                          value: _requierePiezaGrafica,
                          onChanged: (val) {
                            setState(() {
                              _requierePiezaGrafica = val;
                              if (val) _imageFile = null;
                            });
                          },
                          activeTrackColor: theme.primaryColor.withValues(alpha: 0.5),
                          activeThumbColor: theme.primaryColor,
                        ),
                      ],
                    ),
                    
                    if (!_requierePiezaGrafica) ...[
                      const SizedBox(height: 16),
                      GestureDetector(
                        onTap: _pickImage,
                        child: Container(
                          height: 160,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: AppTokens.surface3,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: theme.dividerColor, style: BorderStyle.solid),
                          ),
                          child: _imageBytes != null
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.memory(_imageBytes!, fit: BoxFit.cover),
                              )
                            : (ImageUtils.getFullUrl(widget.editingRequest?.piezaGraficaUrl) != null
                                ? ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: Stack(
                                      fit: StackFit.expand,
                                      children: [
                                        CachedNetworkImage(
                                          imageUrl: ImageUtils.getFullUrl(widget.editingRequest?.piezaGraficaUrl)!,
                                          fit: BoxFit.cover,
                                        ),
                                        Positioned(
                                          right: 8,
                                          bottom: 8,
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                            decoration: BoxDecoration(
                                              color: Colors.black.withValues(alpha: 0.6),
                                              borderRadius: BorderRadius.circular(6),
                                            ),
                                            child: const Text('Toca para cambiar',
                                                style: TextStyle(color: Colors.white, fontSize: 11)),
                                          ),
                                        ),
                                      ],
                                    ),
                                  )
                                : const Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.cloud_upload_outlined, size: 40, color: AppTokens.textMuted),
                                      SizedBox(height: 8),
                                      Text('Toca para subir la pieza gráfica', style: TextStyle(color: AppTokens.textMuted)),
                                    ],
                                  )),
                        ),
                      ),
                    ],

                    const SizedBox(height: 40),
                    GeaButton(
                      text: 'Enviar Solicitud Completa',
                      icon: Icons.send_rounded,
                      isLoading: formState.isLoading,
                      onPressed: _onSubmit,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
