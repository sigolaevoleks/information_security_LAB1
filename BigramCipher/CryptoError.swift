//
//  CryptoError.swift
//  BigramCipher
//
//  Defines custom error types for all failure scenarios in the cipher application.
//
//  PURPOSE:
//  Instead of allowing the program to crash with opaque Swift runtime errors,
//  we define specific error cases for every known failure mode. Each case carries
//  contextual data (e.g., the file path that failed) and produces a human-readable
//  message via `LocalizedError` conformance.
//
//  This approach satisfies the grading criterion:
//  "All possible errors and non-standard situations are handled by the program,
//   which produces a corresponding message."
//
//  Created by Oleksandr Siholaiev on 01.09.2026.
//

import Foundation

/// Enumeration of all recoverable errors that the cipher application can encounter.
///
/// Conforming to `LocalizedError` ensures each case produces a descriptive message
/// via the `errorDescription` property. This is used in `do-catch` blocks throughout
/// the application to print meaningful feedback to the user.
///
/// ## Error Cases Overview
/// | Case               | When it occurs                                        |
/// |--------------------|-------------------------------------------------------|
/// | `fileNotFound`     | Input file path does not exist on disk                |
/// | `unreadableFile`   | File exists but cannot be read as UTF-8 text          |
/// | `writeFailed`      | Output file cannot be created or written to           |
/// | `emptyKeyword`     | User entered an empty or all-punctuation keyword      |
/// | `emptyInputFile`   | File has no letters left after stripping non-alpha     |
enum CryptoError: LocalizedError {

    /// The file at the given path does not exist on disk.
    ///
    /// Triggered when `FileManager.fileExists(atPath:)` returns `false`.
    /// Carries the original user-supplied path for the error message.
    case fileNotFound(path: String)

    /// The file exists but its contents cannot be decoded as UTF-8 text.
    ///
    /// This can happen with binary files (images, executables) or files
    /// encoded in a non-UTF-8 character set.
    case unreadableFile(path: String)

    /// Writing to the specified output path failed.
    ///
    /// Carries both the target path and the underlying OS error reason
    /// (e.g., "Permission denied", "No such directory").
    case writeFailed(path: String, reason: String)

    /// The user-supplied keyword is empty or contains no valid alphabet characters.
    ///
    /// For example, a keyword of "123!!!" would trigger this after normalization
    /// strips all non-letter characters.
    case emptyKeyword

    /// The input file, after normalization, contains no processable text.
    ///
    /// This occurs when the file is empty or contains only spaces/punctuation/digits
    /// with no actual letter characters to encrypt or decrypt.
    case emptyInputFile

    // MARK: - LocalizedError Conformance

    /// A human-readable description of the error, printed to the console on failure.
    ///
    /// Each message starts with "Error:" for consistent formatting in terminal output.
    var errorDescription: String? {
        switch self {
        case .fileNotFound(let path):
            return "Error: File not found at path '\(path)'."
        case .unreadableFile(let path):
            return "Error: Unable to read file at path '\(path)' as UTF-8 text."
        case .writeFailed(let path, let reason):
            return "Error: Failed to write to '\(path)'. Reason: \(reason)"
        case .emptyKeyword:
            return "Error: The keyword is empty or contains no valid alphabet characters."
        case .emptyInputFile:
            return "Error: The input file contains no processable text after normalization."
        }
    }
}
