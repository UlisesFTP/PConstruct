// lib/features/components/pages/component_detail.dart
import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:my_app/models/component.dart';
import 'package:my_app/models/component_review.dart';
import 'package:my_app/models/comment_componente.dart';
import 'package:my_app/models/offer.dart';
import 'package:my_app/core/api/api_client.dart';
import 'package:intl/intl.dart';

class ComponentDetailPage extends StatefulWidget {
  final int componentId;
  const ComponentDetailPage({super.key, required this.componentId});

  @override
  State<ComponentDetailPage> createState() => _ComponentDetailPageState();
}

class _ComponentDetailPageState extends State<ComponentDetailPage> {
  late Future<ComponentDetail> _detailFuture;
  late ApiClient _apiClient;

  final TextEditingController _commentController = TextEditingController();
  final TextEditingController _reviewController = TextEditingController();
  int _reviewRating = 0;

  @override
  void initState() {
    super.initState();
    _apiClient = Provider.of<ApiClient>(context, listen: false);
    _fetchData();
  }

  void _fetchData() {
    setState(() {
      _detailFuture = _apiClient.fetchComponentDetail(widget.componentId);
    });
  }

  Future<void> _postReview() async {
    if (_reviewController.text.isEmpty || _reviewRating == 0) {
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
      );

      _reviewController.clear();
      setState(() {
        _reviewRating = 0;
      });
      _fetchData();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('¡Reseña enviada con éxito!'),
            backgroundColor: Color(0xFFC7384D),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error al enviar reseña: $e')));
      }
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
    return FutureBuilder<ComponentDetail>(
      future: _detailFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(64.0),
              child: CircularProgressIndicator(color: Color(0xFFC7384D)),
            ),
          );
        }

        if (snapshot.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  Text(
                    'Error al cargar: ${snapshot.error}',
                    style: const TextStyle(color: Colors.white),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _fetchData,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFC7384D),
                    ),
                    child: const Text('Reintentar'),
                  ),
                ],
              ),
            ),
          );
        }

        if (snapshot.hasData) {
          final component = snapshot.data!;
          return _ResponsiveLayout(
            component: component,
            reviewRating: _reviewRating,
            reviewController: _reviewController,
            onRatingChanged: (rating) => setState(() => _reviewRating = rating),
            onPostReview: _postReview,
          );
        }

        return const Center(child: Text('Iniciando...'));
      },
    );
  }
}

// Widget principal con layout responsive
class _ResponsiveLayout extends StatelessWidget {
  final ComponentDetail component;
  final int reviewRating;
  final TextEditingController reviewController;
  final Function(int) onRatingChanged;
  final VoidCallback onPostReview;

  const _ResponsiveLayout({
    required this.component,
    required this.reviewRating,
    required this.reviewController,
    required this.onRatingChanged,
    required this.onPostReview,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final isMobile = width < 768;
        final isTablet = width >= 768 && width < 1024;
        final isDesktop = width >= 1024;

        return SingleChildScrollView(
          padding: EdgeInsets.symmetric(
            horizontal: isMobile ? 16 : (isTablet ? 24 : 32),
            vertical: isMobile ? 16 : 24,
          ),
          child: Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: isDesktop ? 1200 : double.infinity,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildBreadcrumbs(context, component),
                  SizedBox(height: isMobile ? 16 : 24),

                  // Layout de 2 columnas en desktop
                  if (isDesktop) ...[
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          flex: 2,
                          child: Column(
                            children: [
                              _buildMainSection(context, component, isMobile),
                              const SizedBox(height: 24),
                              _buildCommentsSection(
                                context,
                                component,
                                reviewRating,
                                reviewController,
                                onRatingChanged,
                                onPostReview,
                                isMobile,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 24),
                        Expanded(
                          flex: 1,
                          child: Column(
                            children: [
                              _buildRatingSection(context, component, isMobile),
                              const SizedBox(height: 24),
                              _buildPricesSection(context, component, isMobile),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ] else ...[
                    // Layout de 1 columna en mobile/tablet
                    _buildMainSection(context, component, isMobile),
                    SizedBox(height: isMobile ? 16 : 24),
                    _buildRatingSection(context, component, isMobile),
                    SizedBox(height: isMobile ? 16 : 24),
                    _buildPricesSection(context, component, isMobile),
                    SizedBox(height: isMobile ? 16 : 24),
                    _buildCommentsSection(
                      context,
                      component,
                      reviewRating,
                      reviewController,
                      onRatingChanged,
                      onPostReview,
                      isMobile,
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildBreadcrumbs(BuildContext context, ComponentDetail component) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
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
          component.category,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildMainSection(
    BuildContext context,
    ComponentDetail component,
    bool isMobile,
  ) {
    return _GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            component.name,
            style: TextStyle(
              color: Colors.white,
              fontSize: isMobile ? 24 : 30,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Componente de tipo ${component.category} fabricado por ${component.brand ?? "N/A"}.',
            style: TextStyle(
              color: const Color(0xFFA0A0A0),
              fontSize: isMobile ? 14 : 16,
            ),
          ),
          const SizedBox(height: 24),

          // Imagen responsive
          Center(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child:
                  component.imageUrl != null && component.imageUrl!.isNotEmpty
                  ? Image.network(
                      component.imageUrl!,
                      width: isMobile ? double.infinity : 300,
                      height: isMobile ? 200 : 300,
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) =>
                          _PlaceholderImage(
                            width: isMobile ? double.infinity : 300,
                            height: isMobile ? 200 : 300,
                          ),
                    )
                  : _PlaceholderImage(
                      width: isMobile ? double.infinity : 300,
                      height: isMobile ? 200 : 300,
                    ),
            ),
          ),

          const SizedBox(height: 24),
          Text(
            'Descripción',
            style: TextStyle(
              color: Colors.white,
              fontSize: isMobile ? 18 : 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            component.description ?? 'No hay descripción disponible.',
            style: TextStyle(
              color: const Color(0xFFE0E0E0),
              fontSize: isMobile ? 14 : 16,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRatingSection(
    BuildContext context,
    ComponentDetail component,
    bool isMobile,
  ) {
    final rating = component.averageRating ?? 0.0;

    return _GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Rating',
            style: TextStyle(
              color: Colors.white,
              fontSize: isMobile ? 18 : 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),

          // Rating display mejorado
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color.fromRGBO(40, 40, 40, 0.5),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFF2A2A2A)),
            ),
            child: Column(
              children: [
                Text(
                  component.reviewCount > 0 ? rating.toStringAsFixed(1) : 'N/A',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: isMobile ? 48 : 56,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(5, (index) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 2),
                      child: Icon(
                        index < rating.floor()
                            ? Icons.star
                            : (index < rating
                                  ? Icons.star_half
                                  : Icons.star_outline),
                        color: rating > 0
                            ? const Color(0xFFC7384D)
                            : const Color(0xFFA0A0A0),
                        size: isMobile ? 24 : 28,
                      ),
                    );
                  }),
                ),
                const SizedBox(height: 12),
                Text(
                  '${component.reviewCount} ${component.reviewCount == 1 ? "reseña" : "reseñas"}',
                  style: const TextStyle(
                    color: Color(0xFFA0A0A0),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCommentsSection(
    BuildContext context,
    ComponentDetail component,
    int reviewRating,
    TextEditingController reviewController,
    Function(int) onRatingChanged,
    VoidCallback onPostReview,
    bool isMobile,
  ) {
    final reviews = component.reviews;

    return _GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Comentarios',
            style: TextStyle(
              color: Colors.white,
              fontSize: isMobile ? 18 : 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),

          if (reviews.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 32.0),
              child: Center(
                child: Column(
                  children: [
                    Icon(
                      Icons.chat_bubble_outline,
                      size: isMobile ? 48 : 64,
                      color: Colors.grey[700],
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      "Sé el primero en comentar.",
                      style: TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: reviews.length,
              separatorBuilder: (context, index) => Padding(
                padding: EdgeInsets.symmetric(vertical: isMobile ? 16 : 24),
                child: const Divider(color: Color(0xFF2A2A2A), height: 1),
              ),
              itemBuilder: (context, index) {
                return ReviewCard(review: reviews[index], isMobile: isMobile);
              },
            ),

          Padding(
            padding: EdgeInsets.symmetric(vertical: isMobile ? 16 : 24),
            child: const Divider(color: Color(0xFF2A2A2A), height: 1),
          ),

          // Formulario de nueva reseña mejorado
          Text(
            'Escribe tu reseña',
            style: TextStyle(
              color: Colors.white,
              fontSize: isMobile ? 16 : 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),

          // Selector de estrellas mejorado
          Container(
            padding: const EdgeInsets.symmetric(vertical: 18),
            decoration: BoxDecoration(
              color: const Color.fromRGBO(40, 40, 40, 0.5),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFF2A2A2A)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  'Tu calificación: ',
                  style: TextStyle(color: Colors.white, fontSize: 12),
                ),
                ...List.generate(5, (index) {
                  return IconButton(
                    icon: Icon(
                      index < reviewRating ? Icons.star : Icons.star_outline,
                      color: const Color(0xFFC7384D),
                      size: isMobile ? 25 : 32,
                    ),
                    onPressed: () => onRatingChanged(index + 1),
                  );
                }),
              ],
            ),
          ),

          const SizedBox(height: 16),

          TextField(
            controller: reviewController,
            decoration: InputDecoration(
              hintText: 'Comparte tu experiencia con este componente...',
              hintStyle: const TextStyle(color: Colors.grey),
              filled: true,
              fillColor: const Color.fromRGBO(40, 40, 40, 0.7),
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
                borderSide: const BorderSide(
                  color: Color(0xFFC7384D),
                  width: 2,
                ),
              ),
              contentPadding: const EdgeInsets.all(16),
            ),
            maxLines: isMobile ? 4 : 5,
            style: const TextStyle(color: Colors.white),
          ),

          const SizedBox(height: 16),

          Align(
            alignment: Alignment.centerRight,
            child: ElevatedButton.icon(
              onPressed: onPostReview,
              icon: const Icon(Icons.send, size: 18),
              label: const Text(
                'Enviar reseña',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFC7384D),
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(
                  horizontal: isMobile ? 20 : 24,
                  vertical: isMobile ? 12 : 14,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPricesSection(
    BuildContext context,
    ComponentDetail component,
    bool isMobile,
  ) {
    final offers = component.offers;
    final bestOffer = offers.isNotEmpty ? offers[0] : null;

    return _GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.local_offer, color: Color(0xFFC7384D), size: 24),
              const SizedBox(width: 8),
              Text(
                'Precios',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: isMobile ? 18 : 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          if (bestOffer == null)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(32.0),
                child: Column(
                  children: [
                    Icon(
                      Icons.shopping_cart_outlined,
                      size: isMobile ? 48 : 64,
                      color: Colors.grey[700],
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      "No hay ofertas de precio disponibles.",
                      style: TextStyle(color: Colors.grey),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            )
          else ...[
            _buildBestOfferCard(context, bestOffer, component, isMobile),
            if (offers.length > 1) ...[
              const SizedBox(height: 20),
              const Text(
                'Otras tiendas',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              _buildStoreGrid(context, offers, isMobile),
            ],
          ],
        ],
      ),
    );
  }

  Widget _buildBestOfferCard(
    BuildContext context,
    Offer bestOffer,
    ComponentDetail component,
    bool isMobile,
  ) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFFC7384D).withOpacity(0.15),
            const Color.fromRGBO(40, 40, 40, 0.7),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFC7384D).withOpacity(0.3)),
      ),
      padding: EdgeInsets.all(isMobile ? 16 : 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFC7384D),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text(
                  'MEJOR PRECIO',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          if (isMobile) ...[
            _buildOfferContent(bestOffer, component, isMobile),
          ] else ...[
            Row(
              children: [
                Expanded(
                  child: _buildOfferContent(bestOffer, component, isMobile),
                ),
                const SizedBox(width: 20),
                _buildOfferImage(component, isMobile),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildOfferContent(
    Offer offer,
    ComponentDetail component,
    bool isMobile,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          component.name,
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: isMobile ? 16 : 18,
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            const Icon(Icons.store, size: 16, color: Color(0xFFA0A0A0)),
            const SizedBox(width: 6),
            Text(
              offer.store,
              style: const TextStyle(color: Color(0xFFA0A0A0), fontSize: 14),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Text(
          '\$${offer.price.toStringAsFixed(0)} MXN',
          style: TextStyle(
            color: Colors.white,
            fontSize: isMobile ? 28 : 32,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: isMobile ? double.infinity : null,
          child: ElevatedButton.icon(
            onPressed: () async {
              final uri = Uri.tryParse(offer.link);
              if (uri != null && await canLaunchUrl(uri)) {
                await launchUrl(uri, mode: LaunchMode.externalApplication);
              }
            },
            icon: const Icon(Icons.shopping_cart, size: 18),
            label: Text(
              'Ver en ${offer.store}',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFC7384D),
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(
                horizontal: isMobile ? 20 : 24,
                vertical: isMobile ? 12 : 14,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildOfferImage(ComponentDetail component, bool isMobile) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: component.imageUrl != null && component.imageUrl!.isNotEmpty
          ? Image.network(
              component.imageUrl!,
              width: isMobile ? double.infinity : 160,
              height: 160,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) =>
                  _PlaceholderImage(width: 160, height: 160),
            )
          : _PlaceholderImage(width: 160, height: 160),
    );
  }

  Widget _buildStoreGrid(
    BuildContext context,
    List<Offer> offers,
    bool isMobile,
  ) {
    return GridView.builder(
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: isMobile ? 2 : 3,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 3.5,
      ),
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: offers.length,
      itemBuilder: (context, index) {
        return _StoreButton(offer: offers[index]);
      },
    );
  }
}

// Widget reutilizable para tarjetas con efecto glass
class _GlassCard extends StatelessWidget {
  final Widget child;

  const _GlassCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          decoration: BoxDecoration(
            color: const Color.fromRGBO(28, 28, 28, 0.7),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFF2A2A2A), width: 1),
          ),
          padding: const EdgeInsets.all(24),
          child: child,
        ),
      ),
    );
  }
}

// Widget para placeholder de imágenes
class _PlaceholderImage extends StatelessWidget {
  final double? width;
  final double? height;

  const _PlaceholderImage({this.width, this.height});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.grey[850],
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Center(
        child: Icon(Icons.image_not_supported, size: 40, color: Colors.grey),
      ),
    );
  }
}

// Botón de tienda mejorado
class _StoreButton extends StatelessWidget {
  final Offer offer;

  const _StoreButton({required this.offer});

  @override
  Widget build(BuildContext context) {
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
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      ),
      child: Text(
        offer.store,
        style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}

// ReviewCard mejorado
class ReviewCard extends StatelessWidget {
  final ComponentReview review;
  final bool isMobile;

  const ReviewCard({super.key, required this.review, required this.isMobile});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(isMobile ? 12 : 16),
      decoration: BoxDecoration(
        color: const Color.fromRGBO(40, 40, 40, 0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF2A2A2A)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: isMobile ? 18 : 22,
                backgroundColor: const Color(0xFFC7384D),
                child: Text(
                  (review.user.userUsername ?? 'A')[0].toUpperCase(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      review.user.userUsername ?? 'Anónimo',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: isMobile ? 14 : 15,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      DateFormat(
                        'dd/MM/yyyy • HH:mm',
                      ).format(review.createdAt.toLocal()),
                      style: TextStyle(
                        color: const Color(0xFFA0A0A0),
                        fontSize: isMobile ? 12 : 13,
                      ),
                    ),
                  ],
                ),
              ),
              // Rating en la esquina
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFC7384D).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: const Color(0xFFC7384D).withOpacity(0.3),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.star, color: Color(0xFFC7384D), size: 16),
                    const SizedBox(width: 4),
                    Text(
                      review.rating.toString(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          if (review.title != null && review.title!.isNotEmpty) ...[
            Text(
              review.title!,
              style: TextStyle(
                color: Colors.white,
                fontSize: isMobile ? 15 : 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
          ],

          Text(
            review.content,
            style: TextStyle(
              color: const Color(0xFFE0E0E0),
              fontSize: isMobile ? 13 : 14,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}
