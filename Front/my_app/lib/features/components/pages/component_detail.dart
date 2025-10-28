import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:my_app/models/component.dart';
import 'package:my_app/models/review.dart';

// Remove main() and MyApp if they were here for testing

class ComponentDetailPage extends StatefulWidget {
  final Component component;
  const ComponentDetailPage({super.key, required this.component});

  @override
  State<ComponentDetailPage> createState() => _ComponentDetailPageState();
}

class _ComponentDetailPageState extends State<ComponentDetailPage> {
  // All helper methods go INSIDE this class
  final TextEditingController _commentController = TextEditingController();

  // --- MOCK DATA REMAINS ---
  final List<Review> reviews = [
    Review(
      userName: 'Carlos M.',
      userAvatar:
          'https://lh3.googleusercontent.com/aida-public/AB6AXuDAI9VouCAj_d1M0x9x7DO-evzw1ce6scJrQdmd14Om24I1ozNfU7BhwUfi9trJ_QHleVknXaf9Plwvu3wpKHIFv57iCfutbZlAAeG3U_x5mnnVXcHpmtRhgP-fNQ63SRio878ZwUdRwwUEvAlHAfwKSfzc11bEZ3Yg5nZqbHZPNl9nLxChkIcicsn32mb5R2gcZqhWbND8HL3-wANx6Z_17fSw9cEe7PWr8vkHxnC61StjZxraAPNRQL9H_SltI4i3ypH849LShvo',
      timeAgo: 'Hace 2 semanas',
      rating: 5,
      comment:
          'Excelente procesador, muy rápido y eficiente. Ideal para juegos y aplicaciones pesadas.',
      likes: 15,
      dislikes: 2,
    ),
    Review(
      userName: 'Ana R.',
      userAvatar:
          'https://lh3.googleusercontent.com/aida-public/AB6AXuDkvJ-Mm7HmmfjA6RLU6-i5pmdBZXP_ZGMYgevLpb47WFJeF5w7eLubUl4qyrXzR39FHerRq-IMw6lz_Bb-v17qwijb2QNsfv_csC_ZMphLiT9mYEjF0oQpUFoqU8nDJ_tcINSZbRNcJcfQLC7wU3MvFm9-AzYLAn24zFqgV9hnnuubS48mnPW_MT4d1ZgNTFCbsPaiB2bFxNX8AiMB0Ij-ZOiDqjQlpdPJXVTq7VoM1ZVzz1VHzdJkynMKZK0-I6mBgvrpJMINeAg',
      timeAgo: 'Hace 1 mes',
      rating: 4,
      comment:
          'Buen rendimiento, pero un poco caro. Cumple con las expectativas.',
      likes: 8,
      dislikes: 1,
    ),
    Review(
      userName: 'Luis G.',
      userAvatar:
          'https://lh3.googleusercontent.com/aida-public/AB6AXuDZokTdYgy02tp0uiv5h7fyZGlfJ1JpDefpG1rEF7AN6FfypvXymVuXycU3uAA5cD_XtKCiOP2_JUcFn16TA9S_p_JZtRkOIC2Op0diaPdOipqiwcGk24IC3K6Rd0K01nTY_TvqcrjwdLl8F5NaF8s3R_rjP0qYybSzHcD8evPmj3WmSkZMZP-FKHlEqIsdRlmEcPtdoLdgAEUrTS2aqeywouHAEqK53B55cVI-Wmi32sqQkOsBkoKTa--TXdptSZLHxwfcWLl3sFk',
      timeAgo: 'Hace 2 meses',
      rating: 3,
      comment:
          'Rendimiento aceptable, pero esperaba más por el precio. Se calienta bastante.',
      likes: 5,
      dislikes: 3,
    ),
  ];
  // --- END MOCK DATA ---

  @override
  void dispose() {
    _commentController.dispose(); // Dispose the controller
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // context is available here
    final theme = Theme.of(context);
    final bool isDesktop = MediaQuery.of(context).size.width >= 768;

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
              _buildBreadcrumbs(), // Methods are called from within the State class
              const SizedBox(height: 24),
              _buildMainSection(),
              const SizedBox(height: 24),
              _buildRatingSection(),
              const SizedBox(height: 24),
              _buildCommentsSection(),
              const SizedBox(height: 24),
              _buildPricesSection(),
            ],
          ),
        ),
      ),
    );
  }

  // --- ALL HELPER METHODS ARE DEFINED *INSIDE* THE STATE CLASS ---

  Widget _buildBreadcrumbs() {
    // Has access to context and widget
    return Wrap(
      spacing: 8,
      children: [
        InkWell(
          onTap: () => Navigator.maybePop(context), // Use context
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
          widget.component.categoria, // Use widget.component
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildMainSection() {
    // Has access to widget
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
                widget.component.name, // Use widget.component
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 30,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Componente de tipo ${widget.component.categoria} fabricado por ${widget.component.marca}.', // Use widget.component
                style: const TextStyle(color: Color(0xFFA0A0A0), fontSize: 16),
              ),
              const SizedBox(height: 24),
              if (widget.component.imageUrl != null &&
                  widget.component.imageUrl!.isNotEmpty) // Use widget.component
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    widget.component.imageUrl!, // Use widget.component
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
                'Aquí iría una descripción más detallada sobre ${widget.component.name}.', // Use widget.component
                style: const TextStyle(color: Color(0xFFE0E0E0), fontSize: 16),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRatingSection() {
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
                      const Text(
                        'N/A',
                        style: TextStyle(
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
                          (index) => const Padding(
                            padding: EdgeInsets.only(right: 4.0),
                            child: Icon(
                              Icons.star_outline,
                              color: Color(0xFFA0A0A0),
                              size: 20,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        '0 reviews',
                        style: TextStyle(
                          color: Color(0xFFA0A0A0),
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(
                    width: 300,
                    child: Column(
                      children: [
                        _buildRatingBar(5, 0.0),
                        const SizedBox(height: 8),
                        _buildRatingBar(4, 0.0),
                        const SizedBox(height: 8),
                        _buildRatingBar(3, 0.0),
                        const SizedBox(height: 8),
                        _buildRatingBar(2, 0.0),
                        const SizedBox(height: 8),
                        _buildRatingBar(1, 0.0),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRatingBar(int stars, double percentage) {
    return Row(
      children: [
        SizedBox(
          width: 20,
          child: Text(
            '$stars',
            style: const TextStyle(color: Colors.white, fontSize: 14),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Container(
            height: 8,
            decoration: BoxDecoration(
              color: const Color(0xFFC7384D).withOpacity(0.2),
              borderRadius: BorderRadius.circular(4),
            ),
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: percentage,
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFC7384D),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        SizedBox(
          width: 50,
          child: Text(
            '${(percentage * 100).toInt()}%',
            style: const TextStyle(color: Color(0xFFA0A0A0), fontSize: 14),
            textAlign: TextAlign.right,
          ),
        ),
      ],
    );
  }

  Widget _buildCommentsSection() {
    // Has access to reviews and _commentController
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
              if (reviews.isEmpty) // Use reviews (defined in State)
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
                  itemCount: reviews.length, // Use reviews
                  separatorBuilder: (context, index) => const Padding(
                    padding: EdgeInsets.symmetric(vertical: 24),
                    child: Divider(color: Color(0xFF2A2A2A), height: 1),
                  ),
                  itemBuilder: (context, index) {
                    return ReviewCard(review: reviews[index]); // Use reviews
                  },
                ),
              const SizedBox(height: 24),
              TextField(
                controller:
                    _commentController, // Use _commentController (defined in State)
                decoration: InputDecoration(
                  hintText: 'Escribe tu comentario...',
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
                  onPressed: () {
                    /* TODO: Lógica para enviar comentario */
                  },
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

  Widget _buildPricesSection() {
    // Has access to widget
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
              ClipRRect(
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
                                    widget.component.name,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ), // Use widget.component
                                  const SizedBox(height: 4),
                                  Text(
                                    'Precio base: \$${widget.component.price.toStringAsFixed(0)} MXN',
                                    style: const TextStyle(
                                      color: Color(0xFFA0A0A0),
                                      fontSize: 14,
                                    ),
                                  ), // Use widget.component
                                  const SizedBox(height: 16),
                                  ElevatedButton.icon(
                                    onPressed: () {
                                      /* TODO: Ver tiendas/comparar */
                                    },
                                    icon: const Icon(
                                      Icons.shopping_cart,
                                      color: Colors.white,
                                      size: 18,
                                    ),
                                    label: const Text(
                                      'Ver Tiendas',
                                      style: TextStyle(
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
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child:
                                  (widget.component.imageUrl != null &&
                                      widget
                                          .component
                                          .imageUrl!
                                          .isNotEmpty) // Use widget.component
                                  ? Image.network(
                                      widget
                                          .component
                                          .imageUrl!, // Use widget.component
                                      width: isMobile ? double.infinity : 192,
                                      height: isMobile ? 150 : 120,
                                      fit: BoxFit.contain,
                                      errorBuilder:
                                          (context, error, stackTrace) =>
                                              Container(
                                                width: isMobile
                                                    ? double.infinity
                                                    : 192,
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
              ),
              const SizedBox(height: 12),
              LayoutBuilder(
                builder: (context, constraints) {
                  final crossAxisCount = constraints.maxWidth < 600
                      ? 2
                      : (constraints.maxWidth < 900 ? 3 : 4);
                  List<Widget> storeButtons = widget
                      .component
                      .stores // Use widget.component
                      .map((storeName) => _buildStoreButton(storeName))
                      .toList();
                  while (storeButtons.length % crossAxisCount != 0 &&
                      storeButtons.isNotEmpty) {
                    storeButtons.add(Container());
                  }
                  if (storeButtons.isEmpty) {
                    return const Padding(
                      padding: EdgeInsets.only(top: 8.0),
                      child: Text(
                        "No hay tiendas disponibles.",
                        style: TextStyle(color: Colors.grey),
                      ),
                    );
                  }
                  return GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: crossAxisCount,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: 3.5,
                    children: storeButtons,
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStoreButton(String storeName) {
    return OutlinedButton(
      onPressed: () {},
      style: OutlinedButton.styleFrom(
        backgroundColor: const Color.fromRGBO(40, 40, 40, 0.7),
        foregroundColor: Colors.white,
        side: const BorderSide(color: Color(0xFF2A2A2A)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        padding: const EdgeInsets.symmetric(vertical: 8),
      ),
      child: Text(
        storeName,
        style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
} // <--- !!! MAKE SURE THIS CLOSING BRACE IS HERE !!!

// --- ReviewCard Class (Must be outside _ComponentDetailPageState) ---
class ReviewCard extends StatelessWidget {
  final Review review;
  const ReviewCard({super.key, required this.review});

  @override
  Widget build(BuildContext context) {
    // ... (ReviewCard implementation remains the same)
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            CircleAvatar(
              radius: 20,
              backgroundImage: NetworkImage(review.userAvatar),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  review.userName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  review.timeAgo,
                  style: const TextStyle(
                    color: Color(0xFFA0A0A0),
                    fontSize: 14,
                  ),
                ),
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
                index < review.rating ? Icons.star : Icons.star_outline,
                color: index < review.rating
                    ? const Color(0xFFC7384D)
                    : const Color(0xFFA0A0A0),
                size: 18,
              ),
            );
          }),
        ),
        const SizedBox(height: 12),
        Text(
          review.comment,
          style: const TextStyle(color: Color(0xFFE0E0E0), fontSize: 15),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            InkWell(
              onTap: () {
                /* TODO: Like comment logic */
              },
              child: Row(
                children: [
                  const Icon(
                    Icons.thumb_up_outlined,
                    color: Color(0xFFA0A0A0),
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${review.likes}',
                    style: const TextStyle(
                      color: Color(0xFFA0A0A0),
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 24),
            InkWell(
              onTap: () {
                /* TODO: Dislike comment logic */
              },
              child: Row(
                children: [
                  const Icon(
                    Icons.thumb_down_outlined,
                    color: Color(0xFFA0A0A0),
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${review.dislikes}',
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
      ],
    );
  }
}
