<?php

namespace App\Events;

use App\Models\Conversation;
use App\Models\Message;
use Illuminate\Broadcasting\Channel;
use Illuminate\Broadcasting\InteractsWithSockets;
use Illuminate\Broadcasting\PresenceChannel;
use Illuminate\Broadcasting\PrivateChannel;
use Illuminate\Contracts\Broadcasting\ShouldBroadcast;
use Illuminate\Foundation\Events\Dispatchable;
use Illuminate\Queue\SerializesModels;

class ConversationStarted implements ShouldBroadcast
{
    use Dispatchable, InteractsWithSockets, SerializesModels;

    public $conversation;
    public $message;

    /**
     * Create a new event instance.
     */
    public function __construct(Conversation $conversation, Message $message)
    {
        $this->conversation = $conversation;
        $this->message = $message;
    }

    /**
     * Get the channels the event should broadcast on.
     */
    public function broadcastOn(): array
    {
        return [
            new PrivateChannel('conversation.' . $this->conversation->id),
            new PrivateChannel('user.' . $this->conversation->member_id),
            new PrivateChannel('user.' . $this->conversation->elder_id),
        ];
    }

    /**
     * The event's broadcast name.
     */
    public function broadcastAs(): string
    {
        return 'conversation.started';
    }

    /**
     * Get the data to broadcast.
     */
    public function broadcastWith(): array
    {
        return [
            'conversation' => [
                'id' => $this->conversation->id,
                'subject' => $this->conversation->subject,
                'status' => $this->conversation->status,
                'member_id' => $this->conversation->member_id,
                'elder_id' => $this->conversation->elder_id,
                'last_message_at' => $this->conversation->last_message_at,
                'member' => [
                    'id' => $this->conversation->member->id,
                    'name' => $this->conversation->member->full_name,
                    'profile_image' => $this->conversation->member->profile_image,
                ],
                'elder' => [
                    'id' => $this->conversation->elder->id,
                    'name' => $this->conversation->elder->full_name,
                    'profile_image' => $this->conversation->elder->profile_image,
                ],
            ],
            'message' => [
                'id' => $this->message->id,
                'conversation_id' => $this->message->conversation_id,
                'sender_id' => $this->message->sender_id,
                'sender_type' => $this->message->sender_type,
                'message' => $this->message->message,
                'message_type' => $this->message->message_type,
                'created_at' => $this->message->created_at,
                'sender' => [
                    'id' => $this->message->sender->id,
                    'name' => $this->message->sender->full_name,
                    'profile_image' => $this->message->sender->profile_image,
                ],
            ],
        ];
    }
}

