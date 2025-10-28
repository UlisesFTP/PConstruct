// lib/models/pc_build.dart

class PCBuild {
  final String name;
  final String createdDate;
  final String cpu;
  final String gpu;
  final String ram;

  PCBuild({
    required this.name,
    required this.createdDate,
    required this.cpu,
    required this.gpu,
    required this.ram,
  });

  // TODO: Añadir un factory constructor .fromJson() cuando tengamos el endpoint
}
