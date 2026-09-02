//
//  CipherConfiguration.swift
//  BigramCipher
//
//  Contains all named constants used throughout the Playfair bigram cipher application.
//
//  PURPOSE:
//  This file serves as the single source of truth for every configurable parameter.
//  By centralizing constants here, we ensure:
//    - Zero "magic numbers" scattered across the codebase.
//    - Easy reconfiguration without modifying cipher logic.
//    - Full compliance with the structured programming requirement.
//
//  HOW THE PLAYFAIR ALPHABET WORKS:
//  The standard English Playfair cipher uses a 25-letter alphabet arranged in a 5×5 grid.
//  Since 26 letters don't fit evenly into a 5×5 matrix (25 cells), one letter must be
//  excluded. By convention, 'J' is merged with 'I' — any 'J' in the input text is
//  treated as 'I' before encryption. This is the most common variant used in textbooks.
//
//  Created by Oleksandr Siholaiev on 01.09.2026.
//

import Foundation

/// Central configuration for the Playfair bigram cipher.
///
/// All parameters that control cipher behavior are defined here as named constants.
/// No numeric or character literals should appear in the cipher engine, matrix builder,
/// or file service — they should all reference values from this struct.
///
/// ## Example Usage
/// ```swift
/// let size = CipherConfiguration.matrixRowCount  // 5
/// let alpha = CipherConfiguration.alphabet        // "ABCDEFGHIKLMNOPQRSTUVWXYZ"
/// ```
struct CipherConfiguration {

    // MARK: - Alphabet Constants

    /// The 25-character English alphabet used to populate the Playfair matrix.
    ///
    /// The letter 'J' is excluded and normalized to 'I' (standard Playfair convention).
    /// This string defines the exact set of characters that can appear in the matrix
    /// and in cipher input/output.
    static let alphabet: String = "ABCDEFGHIKLMNOPQRSTUVWXYZ"

    /// The character that gets replaced during text normalization.
    ///
    /// In standard Playfair, 'J' is replaced with 'I' so the 26-letter English alphabet
    /// fits into a 25-cell (5×5) matrix. Any occurrence of this character in plaintext
    /// or keyword will be silently substituted before processing.
    static let replacedCharacter: Character = "J"

    /// The character that replaces `replacedCharacter` during normalization.
    ///
    /// Every 'J' becomes 'I'. This means "JULIA" and "IULIA" produce identical ciphertext,
    /// which is an intentional and well-known property of the Playfair cipher.
    static let replacementCharacter: Character = "I"

    // MARK: - Matrix Dimension Constants

    /// Number of rows in the Playfair matrix (5 for the standard English variant).
    ///
    /// Together with `matrixColCount`, determines the total matrix capacity:
    /// `matrixRowCount × matrixColCount = 25` cells, matching the 25-letter alphabet.
    static let matrixRowCount: Int = 5

    /// Number of columns in the Playfair matrix (5 for the standard English variant).
    static let matrixColCount: Int = 5

    // MARK: - Cipher Operation Constants

    /// The shift offset applied when two bigram characters share the same row or column.
    ///
    /// During encryption, characters are shifted by +shiftStep positions (right or down).
    /// During decryption, they are shifted by -shiftStep positions (left or up).
    /// Wrapping is applied via modular arithmetic so the shift "wraps around" the matrix.
    static let shiftStep: Int = 1

    /// Character appended to the end of normalized text when its length is odd.
    ///
    /// The Playfair cipher requires all text to be split into pairs (bigrams).
    /// If the normalized text has an odd number of characters, this filler character
    /// is appended to ensure the final character has a partner.
    ///
    /// Common choices are 'X' or 'Z'. We use 'X' as it is the standard convention.
    static let fillerCharacter: Character = "X"
}
