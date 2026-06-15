// lib/features/posts/presentation/widgets/post_editor_shell.dart (Alternative)
import 'package:admin_dashboard/features/posts/data/models/post_model.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../state/posts_controller.dart';
import 'post_form_page.dart';

class PostEditorShell extends StatelessWidget {
  final Post? post;

  const PostEditorShell({super.key, this.post});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => PostsController(),
      child: _PostEditorContent(post: post),
    );
  }
}

class _PostEditorContent extends StatelessWidget {
  final Post? post;

  _PostEditorContent({required this.post});

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<PostsController>();

    return PostFormPage(
      post: post,
      controller: controller,
    );
  }
}
