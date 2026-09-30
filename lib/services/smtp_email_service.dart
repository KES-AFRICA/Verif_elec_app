// lib/services/smtp_email_service.dart
import 'dart:io';
import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server.dart';
import 'package:flutter/foundation.dart';

class SmtpEmailService {
  // ═══════════════════════════════════════════════════════════════
  // CONFIGURATION GMAIL - À REMPLIR
  // ═══════════════════════════════════════════════════════════════
  static const String _email = 'teufackandelson123@gmail.com';  
  static const String _password = 'iobf shfa pmxi iobi';
  
  // Configuration SMTP Gmail
  static const String _smtpServer = 'smtp.gmail.com';
  static const int _smtpPort = 587;
  
  // ═══════════════════════════════════════════════════════════════
  // SÉCURITÉ - LIMITES
  // ═══════════════════════════════════════════════════════════════
  static const int _otpExpirySeconds = 300;      // 5 minutes
  static const int _maxAttemptsPerDay = 5;       // Max 5 demandes par jour
  static const int _resendCooldownSeconds = 60;  // 60 secondes entre envois
  static const int _maxOtpAttempts = 3;          // 3 tentatives max par OTP
  
  // Stockage temporaire (sécurisé)
  static final Map<String, OtpData> _otpStore = {};
  static final Map<String, List<DateTime>> _requestHistory = {};
  
  // ═══════════════════════════════════════════════════════════════
  // ENVOI D'EMAIL AVEC OTP
  // ═══════════════════════════════════════════════════════════════
  
  static Future<OtpResult> sendOtpEmail({
    required String toEmail,
    required String userName,
    required String otpCode,
  }) async {
    try {
      // 1. Vérifier les limites de sécurité
      final securityCheck = _checkSecurityLimits(toEmail);
      if (!securityCheck.allowed) {
        return OtpResult(
          success: false,
          errorMessage: securityCheck.message,
        );
      }
      
      // 2. Configuration du serveur SMTP Gmail (CORRIGÉ)
      final smtpServer = gmail(_email, _password);
      
      // 3. Construction de l'email (CORRIGÉ)
      final message = Message()
        ..from = Address(_email, 'Vérif Elec - KES')
        ..recipients.add(toEmail)
        ..subject = '🔐 Code de réinitialisation - Vérif Elec'
        ..html = _buildEmailTemplate(userName, otpCode)
        ..text = _buildPlainTextEmail(userName, otpCode);
      
      // 4. Envoi (CORRIGÉ)
      final sendReport = await send(message, smtpServer);
      
      // if (sendReport is SendReport && sendReport.hasError) {
      //   print('❌ Erreur envoi: ${sendReport.errors}');
      //   return OtpResult(
      //     success: false,
      //     errorMessage: 'Erreur lors de l\'envoi. Vérifiez vos identifiants.',
      //   );
      // }
      
      // Succès
      _storeOtpSecurely(toEmail, otpCode);
      _recordRequest(toEmail);
      
      if (kDebugMode) {
        print('✅ OTP envoyé à $toEmail: $otpCode');
      }
      
      return OtpResult(
        success: true,
        otpId: toEmail,
      );
      
    } catch (e) {
      print('❌ Exception SMTP Gmail: $e');
      
      String userMessage;
      if (e.toString().contains('535')) {
        userMessage = 'Erreur d\'authentification. Vérifiez vos identifiants Gmail et le mot de passe d\'application.';
      } else if (e.toString().contains('550')) {
        userMessage = 'Email rejeté. Veuillez réessayer dans quelques minutes.';
      } else {
        userMessage = 'Erreur de connexion. Vérifiez votre connexion internet.';
      }
      
      return OtpResult(
        success: false,
        errorMessage: userMessage,
      );
    }
  }
  
  // ═══════════════════════════════════════════════════════════════
  // VÉRIFICATION OTP
  // ═══════════════════════════════════════════════════════════════
  
  static bool verifyOtp({
    required String email,
    required String otpCode,
  }) {
    final emailLower = email.toLowerCase();
    final otpData = _otpStore[emailLower];
    
    if (otpData == null) {
      if (kDebugMode) print('⚠️ Aucun OTP trouvé pour $email');
      return false;
    }
    
    // Vérifier l'expiration
    if (DateTime.now().isAfter(otpData.expiryTime)) {
      _otpStore.remove(emailLower);
      if (kDebugMode) print('⚠️ OTP expiré pour $email');
      return false;
    }
    
    // Vérifier les tentatives
    if (otpData.attempts >= _maxOtpAttempts) {
      _otpStore.remove(emailLower);
      if (kDebugMode) print('⚠️ Trop de tentatives pour $email');
      return false;
    }
    
    // Incrémenter les tentatives
    otpData.attempts++;
    
    // Vérifier le code
    if (otpData.code != otpCode) {
      if (kDebugMode) print('⚠️ Code OTP invalide pour $email: $otpCode');
      return false;
    }
    
    // Succès - supprimer l'OTP
    _otpStore.remove(emailLower);
    if (kDebugMode) print('✅ OTP vérifié avec succès pour $email');
    return true;
  }
  
  // ═══════════════════════════════════════════════════════════════
  // RENVOYER OTP
  // ═══════════════════════════════════════════════════════════════
  
  static Future<OtpResult> resendOtp({
    required String email,
    required String userName,
  }) async {
    final emailLower = email.toLowerCase();
    final lastData = _otpStore[emailLower];
    
    // Vérifier le cooldown
    if (lastData != null) {
      final secondsSinceLastSend = DateTime.now().difference(lastData.createdAt).inSeconds;
      if (secondsSinceLastSend < _resendCooldownSeconds) {
        final waitSeconds = _resendCooldownSeconds - secondsSinceLastSend;
        return OtpResult(
          success: false,
          errorMessage: '⏱️ Veuillez patienter ${waitSeconds}s avant de renvoyer un code',
          retryAfterSeconds: waitSeconds,
        );
      }
    }
    
    // Générer un nouvel OTP
    final newOtp = _generateSecureOtp();
    
    // Envoyer le nouvel OTP
    return await sendOtpEmail(
      toEmail: email,
      userName: userName,
      otpCode: newOtp,
    );
  }
  
  // ═══════════════════════════════════════════════════════════════
  // MÉTHODES DE SÉCURITÉ
  // ═══════════════════════════════════════════════════════════════
  
  static SecurityCheckResult _checkSecurityLimits(String email) {
    final emailLower = email.toLowerCase();
    final now = DateTime.now();
    
    // Nettoyer l'historique
    if (_requestHistory.containsKey(emailLower)) {
      _requestHistory[emailLower] = _requestHistory[emailLower]!
          .where((date) => now.difference(date).inHours < 24)
          .toList();
    }
    
    // Vérifier le nombre de demandes par jour
    final todayRequests = _requestHistory[emailLower]?.length ?? 0;
    if (todayRequests >= _maxAttemptsPerDay) {
      return SecurityCheckResult(
        allowed: false,
        message: '📊 Nombre maximum de demandes atteint pour aujourd\'hui. Réessayez demain.',
      );
    }
    
    // Vérifier si un OTP existe et n'est pas expiré
    final existingOtp = _otpStore[emailLower];
    if (existingOtp != null && DateTime.now().isBefore(existingOtp.expiryTime)) {
      final secondsLeft = existingOtp.expiryTime.difference(DateTime.now()).inSeconds;
      return SecurityCheckResult(
        allowed: false,
        message: '📨 Un code a déjà été envoyé. Veuillez patienter ${secondsLeft}s.',
      );
    }
    
    return SecurityCheckResult(allowed: true, message: null);
  }
  
  static void _storeOtpSecurely(String email, String otpCode) {
    _otpStore[email.toLowerCase()] = OtpData(
      code: otpCode,
      createdAt: DateTime.now(),
      expiryTime: DateTime.now().add(Duration(seconds: _otpExpirySeconds)),
      attempts: 0,
    );
  }
  
  static void _recordRequest(String email) {
    final emailLower = email.toLowerCase();
    if (!_requestHistory.containsKey(emailLower)) {
      _requestHistory[emailLower] = [];
    }
    _requestHistory[emailLower]!.add(DateTime.now());
  }
  
  static String _generateSecureOtp() {
    // Génération d'un code à 6 chiffres
    final random = DateTime.now().microsecondsSinceEpoch;
    final seed = (random * 7919) % 1000000;
    final otp = (seed.abs() % 1000000).toString().padLeft(6, '0');
    return otp.substring(0, 6);
  }
  
  // ═══════════════════════════════════════════════════════════════
  // VERSION TEXTE PLAIN (FALLBACK)
  // ═══════════════════════════════════════════════════════════════
  
  static String _buildPlainTextEmail(String userName, String otpCode) {
    return '''
VÉRIF ELEC - RÉINITIALISATION DE MOT DE PASSE

Bonjour $userName,

Nous avons reçu une demande de réinitialisation de votre mot de passe.

VOTRE CODE DE VÉRIFICATION : $otpCode

⏱️ Ce code expire dans 5 minutes.

⚠️ Si vous n'êtes pas à l'origine de cette demande, ignorez cet email.
Ne partagez jamais ce code avec personne.

---
KES INSPECTIONS AND PROJECTS
    ''';
  }
  
  // ═══════════════════════════════════════════════════════════════
  // TEMPLATE EMAIL HTML MODERNE
  // ═══════════════════════════════════════════════════════════════
  
  static String _buildEmailTemplate(String userName, String otpCode) {
    return '''
<!DOCTYPE html>
<html>
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Réinitialisation - Vérif Elec</title>
  <style>
    * {
      margin: 0;
      padding: 0;
      box-sizing: border-box;
    }
    body {
      font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Helvetica, Arial, sans-serif;
      background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
      margin: 0;
      padding: 20px;
    }
    .container {
      max-width: 520px;
      margin: 0 auto;
      background: #ffffff;
      border-radius: 28px;
      overflow: hidden;
      box-shadow: 0 25px 50px -12px rgba(0,0,0,0.25);
    }
    .header {
      background: linear-gradient(135deg, #1F3864 0%, #2c4a80 100%);
      padding: 36px 24px;
      text-align: center;
      position: relative;
    }
    .logo-icon {
      background: rgba(255,255,255,0.15);
      width: 60px;
      height: 60px;
      border-radius: 30px;
      display: flex;
      align-items: center;
      justify-content: center;
      margin: 0 auto 12px;
    }
    .logo-icon span {
      font-size: 30px;
    }
    .logo {
      font-size: 26px;
      font-weight: 700;
      color: #ffffff;
      letter-spacing: 1px;
    }
    .logo span {
      font-weight: 300;
    }
    .badge {
      background: rgba(255,255,255,0.2);
      display: inline-block;
      padding: 4px 12px;
      border-radius: 20px;
      font-size: 12px;
      color: #ffffff;
      margin-top: 12px;
    }
    .content {
      padding: 36px 28px;
    }
    .greeting {
      font-size: 20px;
      font-weight: 600;
      color: #1F3864;
      margin-bottom: 16px;
    }
    .message {
      color: #4a5568;
      line-height: 1.6;
      margin-bottom: 24px;
      font-size: 15px;
    }
    .otp-card {
      background: linear-gradient(135deg, #f8fafc 0%, #f1f5f9 100%);
      border-radius: 20px;
      padding: 24px;
      text-align: center;
      margin: 28px 0;
      border: 1px solid #e2e8f0;
    }
    .otp-label {
      font-size: 12px;
      text-transform: uppercase;
      letter-spacing: 2px;
      color: #64748b;
      margin-bottom: 12px;
    }
    .otp-code {
      font-family: 'Courier New', 'SF Mono', monospace;
      font-size: 38px;
      font-weight: 700;
      letter-spacing: 12px;
      color: #1F3864;
      background: #ffffff;
      display: inline-block;
      padding: 12px 20px;
      border-radius: 14px;
      box-shadow: 0 4px 12px rgba(0,0,0,0.05);
    }
    .timer {
      font-size: 12px;
      color: #64748b;
      margin-top: 12px;
      display: flex;
      align-items: center;
      justify-content: center;
      gap: 6px;
    }
    .warning-box {
      background: #fef2f2;
      border-left: 4px solid #ef4444;
      padding: 14px 16px;
      border-radius: 12px;
      margin: 24px 0;
      font-size: 13px;
      color: #dc2626;
    }
    .info-box {
      background: #eef2ff;
      border-left: 4px solid #1F3864;
      padding: 14px 16px;
      border-radius: 12px;
      margin: 20px 0;
      font-size: 13px;
      color: #1F3864;
    }
    .footer {
      background: #f8fafc;
      padding: 24px;
      text-align: center;
      border-top: 1px solid #e2e8f0;
    }
    .footer-text {
      font-size: 11px;
      color: #94a3b8;
      margin-bottom: 8px;
    }
    .company {
      font-size: 11px;
      color: #64748b;
      font-weight: 500;
    }
    @media (max-width: 480px) {
      .content {
        padding: 24px 20px;
      }
      .otp-code {
        font-size: 28px;
        letter-spacing: 6px;
        padding: 8px 16px;
      }
      .greeting {
        font-size: 18px;
      }
    }
  </style>
</head>
<body>
  <div class="container">
    <div class="header">
      <div class="logo-icon">
        <span>⚡</span>
      </div>
      <div class="logo">INSPEC<span>APP</span></div>
      <div class="badge">KES INSPECTIONS & PROJECTS</div>
    </div>
    <div class="content">
      <div class="greeting">Bonjour ${_escapeHtml(userName)},</div>
      <div class="message">
        Nous avons reçu une demande de réinitialisation de votre mot de passe.
        Utilisez le code ci-dessous pour sécuriser votre compte.
      </div>
      <div class="otp-card">
        <div class="otp-label">CODE DE VÉRIFICATION</div>
        <div class="otp-code">$otpCode</div>
        <div class="timer">
          <span>⏱️</span> Ce code expire dans 5 minutes
        </div>
      </div>
      <div class="warning-box">
        ⚠️ <strong>Important :</strong> Si vous n'êtes pas à l'origine de cette demande, 
        ignorez cet email. Ne partagez jamais ce code.
      </div>
      <div class="info-box">
        ℹ️ Vous avez droit à <strong>5 demandes par jour</strong> pour des raisons de sécurité.
      </div>
    </div>
    <div class="footer">
      <div class="footer-text">
        Cet email a été envoyé automatiquement. Merci de ne pas y répondre.
      </div>
      <div class="company">
        © ${DateTime.now().year} KES INSPECTIONS AND PROJECTS — Tous droits réservés
      </div>
    </div>
  </div>
</body>
</html>
    ''';
  }
  
  static String _escapeHtml(String text) {
    return text
        .replaceAll('&', '&amp;')
        .replaceAll('<', '&lt;')
        .replaceAll('>', '&gt;')
        .replaceAll('"', '&quot;')
        .replaceAll("'", '&#39;');
  }
  
  // ═══════════════════════════════════════════════════════════════
  // MÉTHODES UTILITAIRES
  // ═══════════════════════════════════════════════════════════════
  
  static void cleanupExpiredOtps() {
    final now = DateTime.now();
    _otpStore.removeWhere((_, data) => now.isAfter(data.expiryTime));
  }
  
  static int? getRemainingSeconds(String email) {
    final data = _otpStore[email.toLowerCase()];
    if (data == null) return null;
    final remaining = data.expiryTime.difference(DateTime.now()).inSeconds;
    return remaining > 0 ? remaining : null;
  }
}

// ═══════════════════════════════════════════════════════════════
// CLASSES DE SUPPORT
// ═══════════════════════════════════════════════════════════════

class OtpData {
  final String code;
  final DateTime createdAt;
  final DateTime expiryTime;
  int attempts;
  
  OtpData({
    required this.code,
    required this.createdAt,
    required this.expiryTime,
    this.attempts = 0,
  });
}

class OtpResult {
  final bool success;
  final String? errorMessage;
  final String? otpId;
  final int? retryAfterSeconds;
  
  OtpResult({
    required this.success,
    this.errorMessage,
    this.otpId,
    this.retryAfterSeconds,
  });
}

class SecurityCheckResult {
  final bool allowed;
  final String? message;
  
  SecurityCheckResult({required this.allowed, this.message});
}