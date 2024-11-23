document.addEventListener('DOMContentLoaded', () => {
    let isDragging = false;
    let offsetX, offsetY;
    const engineHeatUI = document.getElementById('engine-heat-ui');
    const healthNumber = document.getElementById('health-number');
    let beepSound = new Audio('beep.wav'); // Initialize beep sound outside to ensure scope

    beepSound.loop = true;
    beepSound.volume = 1.0;
    beepSound.playing = false;

    function setDragging(state) {
        isDragging = state;
        document.body.style.cursor = state ? 'move' : 'default';
    }

    function handleDrag(e) {
        if (isDragging) {
            engineHeatUI.style.left = `${e.clientX - offsetX}px`;
            engineHeatUI.style.top = `${e.clientY - offsetY}px`;
        }
    }

    function showNotification(message) {
        const notification = document.getElementById('notification');
        notification.textContent = message;
        notification.style.display = 'block';
        setTimeout(() => {
            notification.style.display = 'none';
        }, 3000); // Adjust the timeout duration as needed
    }

    document.addEventListener('mousedown', (e) => {
        if (e.target.closest('#engine-heat-ui')) {
            setDragging(true);
            offsetX = e.clientX - engineHeatUI.getBoundingClientRect().left;
            offsetY = e.clientY - engineHeatUI.getBoundingClientRect().top; // Corrected to top
        }
    });

    document.addEventListener('mouseup', () => setDragging(false));

    document.addEventListener('mousemove', handleDrag);

    document.addEventListener('keydown', (e) => {
        if (e.key === 'Escape') {
            setDragging(false);
            fetch(`https://${GetParentResourceName()}/close_ui`, {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' }
            });
        }
    });

    window.addEventListener('message', (event) => {
        const { action, temperature, engineHealth, color, message } = event.data;

        switch (action) {
            case 'updateTemperature':
                const healthPercent = (engineHealth / 1000) * 100;

                healthNumber.textContent = Math.round(healthPercent);

                const icon = document.getElementById('engine-icon');

                if (temperature < 50) {
                    icon.src = "engine-icon-normal.png";
                    icon.classList.remove('blink');
                } else if (temperature < 80) {
                    icon.src = "engine-icon-orange.png";
                    icon.classList.remove('blink');
                } else if (temperature < 90) {
                    icon.src = "engine-icon-red.png";
                    icon.classList.remove('blink');
                } else {
                    icon.src = "engine-icon-red.png";
                    icon.classList.add('blink');
                }

                if (temperature >= 90) {
                    if (!beepSound.playing) {
                        beepSound.play().then(() => {
                            beepSound.playing = true;
                        }).catch(() => {});
                    }
                } else if (temperature < 90) {
                    beepSound.pause();
                    beepSound.currentTime = 0;
                    beepSound.playing = false;
                }
                break;

            case 'showUI':
                engineHeatUI.style.display = 'flex';
                break;

            case 'hideUI':
                engineHeatUI.style.display = 'none';
                break;

            case 'unlockMouse':
                document.body.style.cursor = 'default';
                engineHeatUI.style.position = 'absolute';
                break;

            case 'updateColor':
                healthNumber.style.color = color;
                healthNumber.style.backgroundColor = 'transparent';
                break;

            case 'showNotification':
                showNotification(message);
                break;
        }
    });
});
