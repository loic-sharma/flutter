// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_SHELL_PLATFORM_COMMON_CLIENT_WRAPPER_INCLUDE_FLUTTER_BINARY_MESSENGER_H_
#define FLUTTER_SHELL_PLATFORM_COMMON_CLIENT_WRAPPER_INCLUDE_FLUTTER_BINARY_MESSENGER_H_

#include <cstdint>
#include <functional>
#include <string>
#include <vector>

namespace flutter {

// A binary message reply callback.
//
// Used for submitting a binary reply back to a Flutter message sender.
typedef std::function<void(const uint8_t* reply, size_t reply_size)>
    BinaryReply;

// A message handler callback.
//
// Used for receiving messages from Flutter and providing an asynchronous reply.
typedef std::function<
    void(const uint8_t* message, size_t message_size, BinaryReply reply)>
    BinaryMessageHandler;

// A synchronous message handler callback.
//
// Used for receiving messages from Flutter and returning the reply
// synchronously. Runs on the platform thread; must return promptly without
// blocking. Return the reply bytes (an empty vector is a valid empty reply).
typedef std::function<std::vector<uint8_t>(const uint8_t* message,
                                           size_t message_size)>
    SyncBinaryMessageHandler;

// A protocol for a class that handles communication of binary data on named
// channels to and from the Flutter engine.
class BinaryMessenger {
 public:
  virtual ~BinaryMessenger() = default;

  // Sends a binary message to the Flutter engine on the specified channel.
  //
  // If |reply| is provided, it will be called back with the response from the
  // engine.
  virtual void Send(const std::string& channel,
                    const uint8_t* message,
                    size_t message_size,
                    BinaryReply reply = nullptr) const = 0;

  // Registers a message handler for incoming binary messages from the Flutter
  // side on the specified channel.
  //
  // Replaces any existing handler. Provide a null handler to unregister the
  // existing handler.
  virtual void SetMessageHandler(const std::string& channel,
                                 BinaryMessageHandler handler) = 0;

  // Sends a binary message to the Flutter engine on the specified channel and
  // blocks until the engine returns the reply.
  //
  // Only supported when the engine runs with merged UI and platform threads
  // (the default unless the embedder opted out). Must be called on the platform
  // thread. On failure (threads not merged, or no synchronous handler is
  // registered on the Flutter side) logs an error and returns an empty reply.
  //
  // The default implementation reports that synchronous messages are not
  // supported and returns an empty reply.
  virtual std::vector<uint8_t> SendSync(const std::string& channel,
                                        const uint8_t* message,
                                        size_t message_size) const {
    return {};
  }

  // Registers a synchronous handler for incoming binary messages from the
  // Flutter side on the specified channel.
  //
  // Replaces any existing synchronous handler. Provide a null handler to
  // unregister. The default implementation does nothing.
  virtual void SetSyncMessageHandler(const std::string& channel,
                                     SyncBinaryMessageHandler handler) {}
};

}  // namespace flutter

#endif  // FLUTTER_SHELL_PLATFORM_COMMON_CLIENT_WRAPPER_INCLUDE_FLUTTER_BINARY_MESSENGER_H_
