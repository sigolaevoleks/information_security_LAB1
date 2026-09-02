//
//  FileService.swift
//  BigramCipher
//
//  Provides safe file read/write operations with comprehensive error handling.
//
//  PURPOSE:
//  All file system interactions in the application are routed through this service.
//  This ensures consistent error handling — every I/O failure is caught and reported
//  as a `CryptoError` with a descriptive message, rather than causing a crash.
//
//  DESIGN NOTES:
//  - Uses `FileManager` for existence checks and raw data reading.
//  - Supports tilde (~) expansion for home directory paths.
//  - All methods are static — no instance state is needed for file operations.
//  - The service does NOT modify file contents; it reads/writes raw strings as-is.
//    Text normalization is handled separately by `BigramCipherEngine`.
//
//  Created by Oleksandr Siholaiev on 01.09.2026.
//

import Foundation

/// Service responsible for reading and writing text files.
///
/// Uses `CryptoError` to report failures with descriptive messages
/// instead of allowing unhandled exceptions to crash the program.
///
/// ## Usage Example
/// ```swift
/// let text = try FileService.readFile(at: "~/Documents/input.txt")
/// try FileService.writeFile(content: "encrypted data", to: "output.txt")
/// ```
struct FileService {

    /// Reads the entire contents of a text file at the given path.
    ///
    /// The method performs two validation steps:
    /// 1. Checks that the file exists on disk (throws `.fileNotFound` if not).
    /// 2. Attempts to decode the file data as UTF-8 (throws `.unreadableFile` if it fails).
    ///
    /// Tilde (`~`) in paths is automatically expanded to the user's home directory,
    /// so both `"~/Desktop/file.txt"` and `"/Users/name/Desktop/file.txt"` work.
    ///
    /// - Parameter path: Absolute or relative path to the input file.
    /// - Returns: The file contents as a `String`.
    /// - Throws: `CryptoError.fileNotFound` if the file does not exist,
    ///           `CryptoError.unreadableFile` if it cannot be decoded as UTF-8.
    static func readFile(at path: String) throws -> String {
        let fileManager = FileManager.default

        // Expand tilde (~) for home directory paths (e.g., ~/Documents/...)
        let expandedPath = NSString(string: path).expandingTildeInPath

        // Verify the file exists before attempting to read it
        guard fileManager.fileExists(atPath: expandedPath) else {
            throw CryptoError.fileNotFound(path: path)
        }

        // Read raw bytes and attempt UTF-8 decoding
        guard let contents = fileManager.contents(atPath: expandedPath),
              let text = String(data: contents, encoding: .utf8) else {
            throw CryptoError.unreadableFile(path: path)
        }

        return text
    }

    /// Writes a string to a file at the given path, creating it if necessary.
    ///
    /// Uses atomic writing (`atomically: true`) to prevent partial writes —
    /// the content is first written to a temporary file, then renamed to the
    /// target path. This ensures the output file is never left in a corrupted state.
    ///
    /// - Parameters:
    ///   - content: The text content to write (e.g., encrypted or decrypted result).
    ///   - path: Absolute or relative path to the output file.
    /// - Throws: `CryptoError.writeFailed` if the write operation fails,
    ///           with the underlying OS error reason included in the message.
    static func writeFile(content: String, to path: String) throws {
        // Expand tilde for consistency with readFile
        let expandedPath = NSString(string: path).expandingTildeInPath

        do {
            try content.write(toFile: expandedPath, atomically: true, encoding: .utf8)
        } catch {
            throw CryptoError.writeFailed(path: path, reason: error.localizedDescription)
        }
    }
}
