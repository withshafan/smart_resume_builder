import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/resume.dart';

class ResumeService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Get current user ID
  String? get currentUserId => _auth.currentUser?.uid;

  // Create a new resume
  Future<void> createResume(Resume resume) async {
    if (currentUserId == null) throw Exception('User not authenticated');
    await _firestore
        .collection('users')
        .doc(currentUserId)
        .collection('resumes')
        .doc(resume.id)
        .set(resume.toJson());
  }

  // Get all resumes for current user
  Future<List<Resume>> getResumes() async {
    if (currentUserId == null) throw Exception('User not authenticated');
    final snapshot = await _firestore
        .collection('users')
        .doc(currentUserId)
        .collection('resumes')
        .orderBy('updatedAt', descending: true)
        .get();
    return snapshot.docs.map((doc) => Resume.fromJson(doc.data())).toList();
  }

  // Get a single resume by ID
  Future<Resume> getResume(String resumeId) async {
    if (currentUserId == null) throw Exception('User not authenticated');
    final doc = await _firestore
        .collection('users')
        .doc(currentUserId)
        .collection('resumes')
        .doc(resumeId)
        .get();
    if (!doc.exists) throw Exception('Resume not found');
    return Resume.fromJson(doc.data()!);
  }

  // Update a resume
  Future<void> updateResume(Resume resume) async {
    if (currentUserId == null) throw Exception('User not authenticated');
    await _firestore
        .collection('users')
        .doc(currentUserId)
        .collection('resumes')
        .doc(resume.id)
        .update(resume.toJson());
  }

  // Delete a resume
  Future<void> deleteResume(String resumeId) async {
    if (currentUserId == null) throw Exception('User not authenticated');
    await _firestore
        .collection('users')
        .doc(currentUserId)
        .collection('resumes')
        .doc(resumeId)
        .delete();
  }
}
