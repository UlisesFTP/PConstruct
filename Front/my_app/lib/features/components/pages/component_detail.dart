// lib/features/components/pages/component_detail.dart
import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart'; // Para abrir links

// ¡Importamos los nuevos modelos y el ApiClient!
import 'package:my_app/models/component.dart'; // Trae ComponentDetail
import 'package:my_app/models/component_review.dart';
import 'package:my_app/models/comment_componente.dart';
import 'package:my_app/models/offer.dart';
import 'package:my_app/core/api/api_client.dart';
import 'package:intl/intl.dart';

class ComponentDetailPage extends StatefulWidget {
  // --- ¡CAMBIO EN EL CONSTRUCTOR! ---
  // Ya no recibe un objeto 'Component', solo el ID.
  final int componentId;
  const ComponentDetailPage({super.key, required this.componentId});

  @override
  State<ComponentDetailPage> createState() => _ComponentDetailPageState();
}

class _ComponentDetailPageState extends State<ComponentDetailPage> {
  // --- NUEVO ESTADO PARA DATOS REALES ---
  late Future<ComponentDetail> _detailFuture;
  late ApiClient _apiClient;

  final TextEditingController _commentController = TextEditingController();
  // (Controlador para la *nueva reseña*, no para un comentario a reseña)
  final TextEditingController _reviewController = TextEditingController();
  int _reviewRating = 0; // Para guardar las estrellas seleccionadas

  // --- ¡DATOS MOCK ELIMINADOS! ---
  // final List<Review> reviews = [ ... ];

  @override
  void initState() {
    super.initState();
    // Obtiene el ApiClient y carga los datos
    _apiClient = Provider.of<ApiClient>(context, listen: false);
    _fetchData();
  }

  // --- NUEVA FUNCIÓN PARA OBTENER DATOS ---
  void _fetchData() {
    setState(() {
      _detailFuture = _apiClient.fetchComponentDetail(widget.componentId);
    });
  }

  // --- NUEVA FUNCIÓN PARA ENVIAR RESEÑA ---
  Future<void> _postReview() async {
    if (_reviewController.text.isEmpty || _reviewRating == 0) {
      // Mostrar error
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor, añade un rating y un comentario.'),
        ),
      );
      return;
    }

    try {
      await _apiClient.postReview(
        componentId: widget.componentId,
        rating: _reviewRating,
        content: _reviewController.text,
        // title: (opcional)
      );

      // Limpia los campos y recarga los datos
      _reviewController.clear();
      setState(() {
        _reviewRating = 0;
      });
      _fetchData(); // Vuelve a cargar los detalles (incluyendo la nueva reseña)
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error al enviar reseña: $e')));
    }
  }

  @override
  void dispose() {
    _commentController.dispose();
    _reviewController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool isDesktop = MediaQuery.of(context).size.width >= 768;

    // --- ¡NUEVO: FUTURE BUILDER! ---
    return FutureBuilder<ComponentDetail>(
      future: _detailFuture,
      builder: (context, snapshot) {
        // 1. Estado de Carga
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(64.0),
              child: CircularProgressIndicator(),
            ),
          );
        }

        // 2. Estado de Error
        if (snapshot.hasError) {
          return Center(
            child: Text(
              'Error al cargar: ${snapshot.error}',
              style: const TextStyle(color: Colors.white),
            ),
          );
        }

        // 3. Estado con Datos
        if (snapshot.hasData) {
          final component = snapshot.data!;
          // Construimos la UI real
          return SingleChildScrollView(
            padding: EdgeInsets.symmetric(
              horizontal: isDesktop ? 32 : 24,
              vertical: 24,
            ),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1120),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildBreadcrumbs(component),
                    const SizedBox(height: 24),
                    _buildMainSection(component),
                    const SizedBox(height: 24),
                    _buildRatingSection(component),
                    const SizedBox(height: 24),
                    _buildCommentsSection(component),
                    const SizedBox(height: 24),
                    _buildPricesSection(component),
                  ],
                ),
              ),
            ),
          );
        }

        // Estado por defecto (no debería llegar aquí)
        return const Center(child: Text('Iniciando...'));
      },
    );
  }

  // --- TODOS LOS MÉTODOS HELPER AHORA RECIBEN EL MODELO 'ComponentDetail' ---

  Widget _buildBreadcrumbs(ComponentDetail component) {
    return Wrap(
      spacing: 8,
      children: [
        InkWell(
          onTap: () => Navigator.of(context).pushNamed('/components'),
          child: const Text(
            'Componentes',
            style: TextStyle(
              color: Color(0xFFA0A0A0),
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        const Text(
          '/',
          style: TextStyle(color: Color(0xFFA0A0A0), fontSize: 14),
        ),
        Text(
          component.category, // <-- Dato real
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildMainSection(ComponentDetail component) {
    // ... (igual, pero usa 'component' real)
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          decoration: BoxDecoration(
            color: const Color.fromRGBO(28, 28, 28, 0.7),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFF2A2A2A), width: 1),
          ),
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                component.name, // <-- Dato real
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 30,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Componente de tipo ${component.category} fabricado por ${component.brand ?? "N/A"}.', // <-- Dato real
                style: const TextStyle(color: Color(0xFFA0A0A0), fontSize: 16),
              ),
              const SizedBox(height: 24),
              if (component.imageUrl != null && component.imageUrl!.isNotEmpty)
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    component.imageUrl!, // <-- Dato real
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      height: 200,
                      color: Colors.grey[800],
                      child: const Center(
                        child: Icon(Icons.broken_image, color: Colors.grey),
                      ),
                    ),
                  ),
                )
              else
                Container(
                  height: 200,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.grey[850],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.image_not_supported,
                      size: 40,
                      color: Colors.grey,
                    ),
                  ),
                ),
              const SizedBox(height: 24),
              const Text(
                'Descripción',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                component.description ??
                    'No hay descripción disponible.', // <-- Dato real
                style: const TextStyle(color: Color(0xFFE0E0E0), fontSize: 16),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRatingSection(ComponentDetail component) {
    // ¡Sección actualizada con datos reales!
    final rating = component.averageRating ?? 0.0;

    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          decoration: BoxDecoration(
            color: const Color.fromRGBO(28, 28, 28, 0.7),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFF2A2A2A), width: 1),
          ),
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Rating',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 32,
                runSpacing: 24,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        // <-- Dato real
                        component.reviewCount > 0
                            ? rating.toStringAsFixed(1)
                            : 'N/A',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 36,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: List.generate(
                          5,
                          (index) => Padding(
                            padding: const EdgeInsets.only(right: 4.0),
                            child: Icon(
                              // <-- Lógica de estrellas real
                              index < rating.floor()
                                  ? Icons.star
                                  : (index < rating
                                        ? Icons.star_half
                                        : Icons.star_outline),
                              color: rating > 0
                                  ? Color(0xFFC7384D)
                                  : Color(0xFFA0A0A0),
                              size: 20,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        // <-- Dato real
                        '${component.reviewCount} reviews',
                        style: const TextStyle(
                          color: Color(0xFFA0A0A0),
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                  // (Las barras de porcentaje se pueden implementar después)
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCommentsSection(ComponentDetail component) {
    // ¡Sección actualizada con datos reales!
    final reviews = component.reviews; // <-- Dato real

    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          decoration: BoxDecoration(
            color: const Color.fromRGBO(28, 28, 28, 0.7),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFF2A2A2A), width: 1),
          ),
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Comentarios',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              if (reviews.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 32.0),
                  child: Center(
                    child: Text(
                      "Sé el primero en comentar.",
                      style: TextStyle(color: Colors.grey),
                    ),
                  ),
                )
              else
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: reviews.length,
                  separatorBuilder: (context, index) => const Padding(
                    padding: EdgeInsets.symmetric(vertical: 24),
                    child: Divider(color: Color(0xFF2A2A2A), height: 1),
                  ),
                  itemBuilder: (context, index) {
                    // Pasa el nuevo modelo ComponentReview
                    return ReviewCard(review: reviews[index]);
                  },
                ),
              const SizedBox(height: 24),
              const Divider(color: Color(0xFF2A2A2A), height: 1),
              const SizedBox(height: 24),
              // --- Formulario para NUEVA RESEÑA ---
              const Text(
                'Escribe tu reseña',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 16),
              // Selector de Estrellas
              Row(
                children: List.generate(5, (index) {
                  return IconButton(
                    icon: Icon(
                      index < _reviewRating ? Icons.star : Icons.star_outline,
                      color: Color(0xFFC7384D),
                    ),
                    onPressed: () {
                      setState(() {
                        _reviewRating = index + 1;
                      });
                    },
                  );
                }),
              ),
              const SizedBox(height: 16),
              // Campo de texto para la reseña
              TextField(
                controller: _reviewController,
                decoration: InputDecoration(
                  hintText: 'Escribe tu reseña...',
                  hintStyle: const TextStyle(color: Colors.grey),
                  filled: true,
                  fillColor:
                      Theme.of(
                        context,
                      ).inputDecorationTheme.fillColor?.withOpacity(0.7) ??
                      const Color.fromRGBO(40, 40, 40, 0.7),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: Color(0xFF2A2A2A)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: Color(0xFF2A2A2A)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide:
                        Theme.of(
                          context,
                        ).inputDecorationTheme.focusedBorder?.borderSide ??
                        const BorderSide(color: Color(0xFFC7384D), width: 2),
                  ),
                  contentPadding: const EdgeInsets.all(16),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerRight,
                child: ElevatedButton(
                  onPressed: _postReview, // <-- Llama a la función de posteo
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFC7384D),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 10,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    'Enviar',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPricesSection(ComponentDetail component) {
    // ¡Sección actualizada con datos reales!
    final offers = component.offers;
    final bestOffer = (offers.isNotEmpty) ? offers[0] : null;

    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          decoration: BoxDecoration(
            color: const Color.fromRGBO(28, 28, 28, 0.7),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFF2A2A2A), width: 1),
          ),
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Precios',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),

              if (bestOffer == null)
                const Center(
                  child: Text(
                    "No hay ofertas de precio disponibles.",
                    style: TextStyle(color: Colors.grey),
                  ),
                )
              else
                // Muestra la mejor oferta (la primera de la lista)
                _buildBestOfferCard(bestOffer, component),

              const SizedBox(height: 12),

              // Muestra los botones de todas las tiendas
              LayoutBuilder(
                builder: (context, constraints) {
                  if (offers.isEmpty) return const SizedBox.shrink();

                  final crossAxisCount = constraints.maxWidth < 600
                      ? 2
                      : (constraints.maxWidth < 900 ? 3 : 4);

                  return GridView.builder(
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: crossAxisCount,
                      mainAxisSpacing: 12,
                      crossAxisSpacing: 12,
                      childAspectRatio: 3.5,
                    ),
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: offers.length,
                    itemBuilder: (context, index) {
                      return _buildStoreButton(offers[index]);
                    },
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Widget para la tarjeta de la MEJOR oferta
  Widget _buildBestOfferCard(Offer bestOffer, ComponentDetail component) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          decoration: BoxDecoration(
            color: const Color.fromRGBO(40, 40, 40, 0.7),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFF2A2A2A)),
          ),
          padding: const EdgeInsets.all(16),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final isMobile = constraints.maxWidth < 600;
              return Flex(
                direction: isMobile ? Axis.vertical : Axis.horizontal,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          component.name, // Nombre del componente
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          // Precio de la mejor oferta
                          'Precio base: \$${bestOffer.price.toStringAsFixed(0)} MXN',
                          style: const TextStyle(
                            color: Color(0xFFA0A0A0),
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          onPressed: () async {
                            // ¡Abre el link real!
                            final uri = Uri.tryParse(bestOffer.link);
                            if (uri != null && await canLaunchUrl(uri)) {
                              await launchUrl(
                                uri,
                                mode: LaunchMode.externalApplication,
                              );
                            }
                          },
                          icon: const Icon(
                            Icons.shopping_cart,
                            color: Colors.white,
                            size: 18,
                          ),
                          label: Text(
                            // Botón dice la tienda real
                            'Ver en ${bestOffer.store}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFC7384D),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 10,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (!isMobile) const SizedBox(width: 24),
                  if (isMobile) const SizedBox(height: 16),
                  // Imagen
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child:
                        (component.imageUrl != null &&
                            component.imageUrl!.isNotEmpty)
                        ? Image.network(
                            component.imageUrl!,
                            width: isMobile ? double.infinity : 192,
                            height: isMobile ? 150 : 120,
                            fit: BoxFit.contain,
                            errorBuilder: (context, error, stackTrace) =>
                                Container(
                                  width: isMobile ? double.infinity : 192,
                                  height: isMobile ? 150 : 120,
                                  color: Colors.grey[800],
                                  child: const Center(
                                    child: Icon(
                                      Icons.broken_image,
                                      color: Colors.grey,
                                    ),
                                  ),
                                ),
                          )
                        : Container(
                            /* ... (placeholder de imagen sin cambios) ... */
                            width: isMobile ? double.infinity : 192,
                            height: isMobile ? 150 : 120,
                            decoration: BoxDecoration(
                              color: Colors.grey[850],
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Center(
                              child: Icon(
                                Icons.image_not_supported,
                                size: 40,
                                color: Colors.grey,
                              ),
                            ),
                          ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  // Botón para una tienda (abre el link)
  Widget _buildStoreButton(Offer offer) {
    return OutlinedButton(
      onPressed: () async {
        final uri = Uri.tryParse(offer.link);
        if (uri != null && await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        }
      },
      style: OutlinedButton.styleFrom(
        backgroundColor: const Color.fromRGBO(40, 40, 40, 0.7),
        foregroundColor: Colors.white,
        side: const BorderSide(color: Color(0xFF2A2A2A)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        padding: const EdgeInsets.symmetric(vertical: 8),
      ),
      child: Text(
        offer.store,
        style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}

// --- ReviewCard Class (MODIFICADA) ---
// Ahora usa el modelo ComponentReview
class ReviewCard extends StatelessWidget {
  final ComponentReview review; // <-- ¡Modelo actualizado!
  const ReviewCard({super.key, required this.review});

  @override
  Widget build(BuildContext context) {
    // (Esta la implementaremos después, al conectar los comentarios a reseñas)
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            CircleAvatar(
              radius: 20,
              // (Usamos un placeholder por ahora, la API no devuelve avatar)
              child: Icon(Icons.person),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  review.user.userUsername ?? 'Anónimo', // <-- Dato real
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 2),
                // --- ¡INICIO DE CORRECCIÓN DE FECHA! ---
                Text(
                  // Formatea la fecha a "dd/MM y HH:mm"
                  DateFormat(
                    'dd/MM y HH:mm',
                  ).format(review.createdAt.toLocal()),
                  style: const TextStyle(
                    color: Color(0xFFA0A0A0),
                    fontSize: 14,
                  ),
                ),
                // --- FIN DE CORRECCIÓN! ---
              ],
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: List.generate(5, (index) {
            return Padding(
              padding: const EdgeInsets.only(right: 2),
              child: Icon(
                index < review.rating
                    ? Icons.star
                    : Icons.star_outline, // <-- Dato real
                color: index < review.rating
                    ? const Color(0xFFC7384D)
                    : const Color(0xFFA0A0A0),
                size: 18,
              ),
            );
          }),
        ),
        const SizedBox(height: 12),
        if (review.title != null && review.title!.isNotEmpty) ...[
          Text(
            review.title!, // <-- Dato real (título)
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
        ],
        Text(
          review.content, // <-- Dato real
          style: const TextStyle(color: Color(0xFFE0E0E0), fontSize: 15),
        ),
        const SizedBox(height: 12),
        // (Likes/Dislikes en reseñas no están en la API, los quitamos)
      ],
    );
  }
}
