# Walkie-Talkie Architecture Plan (Custom PTT)

## 1. Sending Logic: "Silent PTT"
To avoid the unprofessional UX of standard voice calls, we use **Voice Notes** with a custom identifier.

- **Trigger**: Long-press a PTT button in the UI.
- **Payload**: Send a Voice Note via `sendMessage`.
- **Custom Identifier**: Append a specific, invisible string or a unique tag like `#PTT_AUDIO` in the `FormattedText` caption.
- **Advantage**: It bypasses the call UI and treats the transmission as a data packet.

## 2. Receiving & Background Auto-Play
This is the core "Live Radio" experience.

- **Background Listener**: Use `flutter_background_service`.
- **Detection**:
    - Listener monitors `UpdateNewMessage`.
    - If `message.content` is `MessageVoiceNote` AND contains the `#PTT_AUDIO` tag.
- **Execution**:
    - Immediately call `downloadFile` for that specific voice note.
    - Monitor `UpdateFile` for completion.
    - Once local path is available, use `just_audio` to play the file through the **loudspeaker** (`AudioSession` configured for speech).
    - **Note**: The user doesn't need to touch their phone; the audio plays as soon as it's received.

## 3. UI & History Filtering
- **Active State**: The main UI shows an animation (e.g., "Incoming PTT from [User]") when the background service reports playback.
- **PTT History View**:
    - A dedicated tab/page that calls `searchChatMessages` or filters local `_messages`.
    - Shows only messages containing the `#PTT_AUDIO` tag.
    - Excludes these messages from the standard chat view to keep the main chat "clean".

---

# ওয়াকি-টকি ইমপ্লিমেন্টেশন প্ল্যান (বাংলা সংস্করণ)

## ১. পাঠানোর লজিক: "সাইলেন্ট PTT"
স্ট্যান্ডার্ড ভয়েস কলের ঝামেলা এড়াতে আমরা **ভয়েস নোট (Voice Notes)** ব্যবহার করব একটি কাস্টম আইডেন্টিফায়ার সহ।

- **ট্রিগার**: UI-তে থাকা PTT বাটনটি চেপে ধরে কথা বলা শুরু হবে।
- **পেলোড**: `sendMessage` এর মাধ্যমে একটি ভয়েস নোট পাঠানো হবে।
- **কাস্টম ট্যাগ**: মেসেজের ক্যাপশনে একটি গোপন ট্যাগ (যেমন: `#PTT_AUDIO`) যোগ করা হবে।
- **সুবিধা**: এটি কোনো রিং বা কল ইন্টারফেস দেখাবে না, সরাসরি ফাইল হিসেবে যাবে।

## ২. রিসিভিং এবং ব্যাকগ্রাউন্ড অটো-প্লে
এটি আপনার অ্যাপটিকে একটি আসল রেডিওর মতো কাজ করতে সাহায্য করবে।

- **ব্যাকগ্রাউন্ড লিসেনার**: `flutter_background_service` ব্যবহার করে অ্যাপ ব্যাকগ্রাউন্ডে সবসময় অ্যাক্টিভ থাকবে।
- **সনাক্তকরণ**:
    - লিসেনার নতুন আসা মেসেজগুলো (`UpdateNewMessage`) চেক করবে।
    - যদি মেসেজটি একটি ভয়েস নোট হয় এবং তাতে `#PTT_AUDIO` ট্যাগটি থাকে।
- **প্লেব্যাক**:
    - সাথে সাথে ফাইলটি ডাউনলোড (`downloadFile`) করা শুরু হবে।
    - ডাউনলোড শেষ হওয়া মাত্রই `just_audio` প্যাকেজ ব্যবহার করে লাউডস্পিকারে অটোমেটিক প্লে হবে।
    - **মনে রাখবেন**: ইউজারকে ফোন টাচ করতে হবে না, মেসেজ আসা মাত্রই আওয়াজ শোনা যাবে।

## ৩. ইউজার ইন্টারফেস এবং হিস্ট্রি ফিল্টারিং
- **অ্যাক্টিভ স্ট্যাটাস**: যখন ব্যাকগ্রাউন্ডে কথা বাজবে, স্ক্রিনে একটি অ্যানিমেশন দেখাবে (যেমন: "Incoming PTT from [User]")।
- **ওয়াকি-টকি হিস্ট্রি ভিউ**:
    - একটি আলাদা পেজ থাকবে যেখানে শুধুমাত্র এই সাইলেন্ট PTT মেসেজগুলো দেখা যাবে।
    - মেইন চ্যাট থেকে এই মেসেজগুলো হাইড করে রাখা হবে যাতে সাধারণ চ্যাট পরিষ্কার থাকে।
