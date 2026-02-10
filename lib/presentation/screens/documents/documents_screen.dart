import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mmm/core/constants/colors.dart';
import 'package:mmm/core/constants/dimensions.dart';
import 'package:mmm/presentation/widgets/common/primary_button.dart';
import 'package:mmm/presentation/cubits/documents/documents_cubit.dart';
import 'package:mmm/presentation/cubits/auth/auth_cubit.dart';
import 'package:mmm/routes/route_names.dart';

class DocumentsScreen extends StatefulWidget {
  const DocumentsScreen({super.key});

  @override
  State<DocumentsScreen> createState() => _DocumentsScreenState();
}

class _DocumentsScreenState extends State<DocumentsScreen> {
  @override
  void initState() {
    super.initState();
    final authState = context.read<AuthCubit>().state;
    if (authState is Authenticated) {
      context.read<DocumentsCubit>().loadDocuments(userId: authState.user.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('المستندات'),
        backgroundColor: AppColors.primary,
        actions: [
          IconButton(
            icon: const Icon(Icons.upload_file),
            onPressed: () =>
                Navigator.pushNamed(context, RouteNames.uploadDocument),
          ),
        ],
      ),
      body: BlocBuilder<DocumentsCubit, DocumentsState>(
        builder: (context, state) {
          if (state is DocumentsLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is DocumentsLoaded) {
            if (state.documents.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.description_outlined,
                      size: 80,
                      color: AppColors.gray300,
                    ),
                    const SizedBox(height: Dimensions.spaceL),
                    Text(
                      'لا توجد مستندات',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: Dimensions.spaceL),
                    PrimaryButton(
                      text: 'رفع مستند',
                      onPressed: () => Navigator.pushNamed(
                        context,
                        RouteNames.uploadDocument,
                      ),
                    ),
                  ],
                ),
              );
            }

            return RefreshIndicator(
              onRefresh: () async {
                final authState = context.read<AuthCubit>().state;
                if (authState is Authenticated) {
                  await context.read<DocumentsCubit>().refreshDocuments(
                    authState.user.id,
                  );
                }
              },
              child: ListView.separated(
                padding: const EdgeInsets.all(Dimensions.spaceL),
                itemCount: state.documents.length,
                separatorBuilder: (_, __) =>
                    const SizedBox(height: Dimensions.spaceM),
                itemBuilder: (context, index) {
                  final doc = state.documents[index];
                  return Card(
                    child: ListTile(
                      leading: Container(
                        padding: const EdgeInsets.all(Dimensions.spaceM),
                        decoration: BoxDecoration(
                          color: AppColors.error.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(
                            Dimensions.radiusM,
                          ),
                        ),
                        child: const Icon(
                          Icons.picture_as_pdf,
                          color: AppColors.error,
                        ),
                      ),
                      title: Text(doc.fileName),
                      subtitle: Text(doc.type.toString()),
                      trailing: IconButton(
                        icon: const Icon(Icons.visibility),
                        onPressed: () => Navigator.pushNamed(
                          context,
                          RouteNames.documentViewer,
                          arguments: doc.id,
                        ),
                      ),
                    ),
                  );
                },
              ),
            );
          }

          return const SizedBox.shrink();
        },
      ),
    );
  }
}
