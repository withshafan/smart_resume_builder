import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/resume.dart';
import '../utils/result.dart';

class ResumeService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? get currentUserId => _auth.currentUser?.uid;

  /// Create a new resume. Returns [Result.ok] on success.
  Future<Result<void>> createResume(Resume resume) async {
    if (currentUserId == null) return Result.authError();
    try {
      await _firestore
          .collection('users')
          .doc(currentUserId)
          .collection('resumes')
          .doc(resume.id)
          .set(resume.toJson())
          .timeout(const Duration(seconds: 10));
      return Result.ok(null);
    } on FirebaseException catch (e) {
      return _mapFirestoreError(e);
    } catch (e) {
      return Result.networkError(cause: e);
    }
  }

  /// Fetch all resumes for the current user, ordered by most recently updated.
  Future<Result<List<Resume>>> getResumes() async {
    if (currentUserId == null) return Result.authError();
    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(currentUserId)
          .collection('resumes')
          .orderBy('updatedAt', descending: true)
          .get()
          .timeout(const Duration(seconds: 10));
      final resumes = snapshot.docs.map((doc) => Resume.fromJson(doc.data())).toList();
      return Result.ok(resumes);
    } on FirebaseException catch (e) {
      return _mapFirestoreError(e);
    } catch (e) {
      return Result.networkError(cause: e);
    }
  }

  /// Fetch a single resume by ID.
  Future<Result<Resume>> getResume(String resumeId) async {
    if (currentUserId == null) return Result.authError();
    try {
      final doc = await _firestore
          .collection('users')
          .doc(currentUserId)
          .collection('resumes')
          .doc(resumeId)
          .get();
      if (!doc.exists) {
        return Result.fail('Resume not found. It may have been deleted.');
      }
      return Result.ok(Resume.fromJson(doc.data()!));
    } on FirebaseException catch (e) {
      return _mapFirestoreError(e);
    } catch (e) {
      return Result.networkError(cause: e);
    }
  }

  /// Update an existing resume.
  Future<Result<void>> updateResume(Resume resume) async {
    if (currentUserId == null) return Result.authError();
    try {
      await _firestore
          .collection('users')
          .doc(currentUserId)
          .collection('resumes')
          .doc(resume.id)
          .update(resume.toJson());
      return Result.ok(null);
    } on FirebaseException catch (e) {
      return _mapFirestoreError(e);
    } catch (e) {
      return Result.networkError(cause: e);
    }
  }

  /// Soft delete a resume by ID.
  Future<Result<void>> deleteResume(String resumeId) async {
    if (currentUserId == null) return Result.authError();
    try {
      await _firestore
          .collection('users')
          .doc(currentUserId)
          .collection('resumes')
          .doc(resumeId)
          .delete()
          .timeout(const Duration(seconds: 10));
      return Result.ok(null);
    } on FirebaseException catch (e) {
      return _mapFirestoreError(e);
    } catch (e) {
      return Result.networkError(cause: e);
    }
  }


  Result<T> _mapFirestoreError<T>(FirebaseException e) {
    return switch (e.code) {
      'permission-denied' => Result.authError(cause: e),
      'unavailable' || 'network-request-failed' => Result.networkError(cause: e),
      _ => Result.fail('Something went wrong (${e.code}). Please try again.', cause: e),
    };
  }
}
