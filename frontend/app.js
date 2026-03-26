const chatMessages = document.getElementById('chatMessages');
const chatInput = document.getElementById('chatInput');
const sendButton = document.getElementById('sendButton');
const API_URL = 'https://aca-surveychat-api-eus2-yx03.happysea-117a7783.eastus2.azurecontainerapps.io/query';
// Store the current thread ID
let currentThreadId = null;

// Add welcome message on load
window.addEventListener('DOMContentLoaded', () => {
    addMessage('Welcome to the Survey chat', 'bot');
    chatInput.focus();
});

// Auto-resize textarea
chatInput.addEventListener('input', function() {
    this.style.height = 'auto';
    this.style.height = Math.min(this.scrollHeight, 150) + 'px';
});

// Handle Enter key (Shift+Enter for new line)
chatInput.addEventListener('keydown', (e) => {
    if (e.key === 'Enter' && !e.shiftKey) {
        e.preventDefault();
        sendMessage();
    }
});

sendButton.addEventListener('click', sendMessage);

function addMessage(content, type = 'bot', isLoading = false) {
    const messageDiv = document.createElement('div');
    messageDiv.className = `message ${type}-message`;
    
    const icon = document.createElement('div');
    icon.className = 'message-icon';
    icon.innerHTML = type === 'user' 
        ? '<i class="fas fa-user"></i>' 
        : '<i class="fas fa-robot"></i>';
    
    const contentDiv = document.createElement('div');
    contentDiv.className = 'message-content';
    
    if (isLoading) {
        contentDiv.innerHTML = '<div class="typing-indicator"><span></span><span></span><span></span></div>';
        messageDiv.id = 'loadingMessage';
    } else {
        // Render Markdown for bot messages, plain text for user messages
        if (type === 'bot') {
            contentDiv.innerHTML = marked.parse(content);
        } else {
            contentDiv.textContent = content;
        }
    }
    
    messageDiv.appendChild(icon);
    messageDiv.appendChild(contentDiv);
    chatMessages.appendChild(messageDiv);
    
    // Scroll to bottom
    chatMessages.scrollTop = chatMessages.scrollHeight;
    
    return messageDiv;
}

function removeLoadingMessage() {
    const loadingMessage = document.getElementById('loadingMessage');
    if (loadingMessage) {
        loadingMessage.remove();
    }
}

async function sendMessage() {
    const message = chatInput.value.trim();
    
    if (!message) return;
    
    // Add user message
    addMessage(message, 'user');
    
    // Clear input
    chatInput.value = '';
    chatInput.style.height = 'auto';
    
    // Disable send button
    sendButton.disabled = true;
    
    // Add loading indicator
    addMessage('', 'bot', true);
    
    try {
        // Build request body
        const requestBody = { request: message };
        if (currentThreadId) {
            requestBody.threadId = currentThreadId;
        }
        
        const response = await fetch(API_URL, {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json',
            },
            body: JSON.stringify(requestBody)
        });
        
        if (!response.ok) {
            throw new Error(`HTTP error! status: ${response.status}`);
        }
        
        // Parse JSON response
        const jsonResponse = await response.json();
        
        // Store thread ID for subsequent requests
        if (jsonResponse.threadId) {
            currentThreadId = jsonResponse.threadId;
        }
        
        // Remove loading indicator
        removeLoadingMessage();
        
        // Add bot response (Markdown will be parsed in addMessage)
        addMessage(jsonResponse.response, 'bot');
        
    } catch (error) {
        console.error('Error:', error);
        
        // Remove loading indicator
        removeLoadingMessage();
        
        // Add error message
        addMessage('Sorry, I encountered an error processing your request. Please try again.', 'bot');
    } finally {
        // Re-enable send button
        sendButton.disabled = false;
        chatInput.focus();
    }
}
