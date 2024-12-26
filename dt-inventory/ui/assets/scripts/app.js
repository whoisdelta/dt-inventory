const inventory = new Vue({
    el: '#inventory',
    data: {
        items: [],
        fastMenuItems: [],
        MyMinCapacity: 0,
        MyMaxCapacity: 100,
        search: "",
        currentCategory: null,
        categories: [
            { id: 'all', icon: './assets/img/ep_menu.svg' },
            { id: 'weapon', icon: './assets/img/submachine-gun-svgrepo-com.svg' },
            { id: 'clothes', icon: './assets/img/black.svg' },
            { id: 'keys', icon: './assets/img/fluent_key-20-filled.svg' },
            { id: 'food', icon: './assets/img/ion_fast-food.svg' },
            { id: 'medics', icon: './assets/img/medical-icon_health-services.svg' },
            { id: 'money', icon: './assets/img/fa-solid_money-bill-wave-alt.svg' }
        ],
        previewModal: {
            show: false,
            item: null,
            style: {
                left: '0px',
                top: '0px'
            }
        },
        countModal: {
            show: false,
            item: null,
            type: null,
            selectedCount: 1,
            style: {
                left: '0px',
                top: '0px'
            }
        },

        vaultData: {
            active: false,
            items: [],
            maxCapacity: 100,
            capacity: 0,
            currentVaultName: ''
        },

        rightSide: {
            name: 'Right Side',
            desc: 'Here you can do different actions'
        }
    },

    computed: {
        filteredItems() {
            let items = this.currentCategory === 'all' || !this.currentCategory ? this.items : this.items.filter(item => item.type === this.currentCategory);

            if (this.search.trim()) {
                const searchTerm = this.search.toLowerCase().trim();
                items = items.filter(item => item.name.toLowerCase().includes(searchTerm) || item.label.toLowerCase().includes(searchTerm));
            }

            return items;
        },

        previewModal: {
            imagePath() {
                if (!this.previewModal.item) return '';
                return this.previewModal.item.type === "weapon"
                    ? `./assets/img/weapons/${this.previewModal.item.name.toUpperCase()}.png`
                    : `./assets/img/items/${this.previewModal.item.name}.png`;
            }
        },

        countModal: {
            imagePath() {
                if (!this.countModal.item) return '';
                return this.countModal.item.type === "weapon"
                    ? `./assets/img/weapons/${this.countModal.item.name.toUpperCase()}.png`
                    : this.countModal.item.type === "account"
                        ? `./assets/img/accounts/${this.countModal.item.name}.png`
                        : `./assets/img/items/${this.countModal.item.name}.png`;
            }
        },

        filteredVaultItems() {
            let items = this.currentCategory === 'all' || !this.currentCategory
                ? this.vaultData.items
                : this.vaultData.items.filter(item => item.type === this.currentCategory);

            if (this.search.trim()) {
                const searchTerm = this.search.toLowerCase().trim();
                items = items.filter(item =>
                    item.name.toLowerCase().includes(searchTerm) ||
                    item.label.toLowerCase().includes(searchTerm)
                );
            }

            return items;
        },
    },

    mounted() {
        $('.inventory').hide();

        window.addEventListener('keydown', this.handleKeyDown);
        window.addEventListener('message', this.handleMessage);

        setTimeout(() => {
            this.$nextTick(() => {
                this.initializeDragAndDrop();
            });
        }, 1000);
    },

    methods: {
        async post(url, data = {}, resource = GetParentResourceName()) {
            try {
                const response = await fetch(`https://${resource}/${url}`, {
                    method: 'POST',
                    headers: { 'Content-Type': 'application/json' },
                    body: JSON.stringify(data)
                });
                return await response.json();
            } catch (error) {
                return {};
            }
        },

        handleKeyDown(event) {
            if (event.key === 'Escape') {
                this.closeInventory();
            }
        },

        ManageClotheSlot(index) {
            // todo

            console.log(index);
        },

        handleMessage(event) {
            var data = event.data.data;

            if (event.data.action === 'openMenu') {
                $('.inventory').fadeIn(100);
                this.items = Object.values(data.items || {});
                this.MyMaxCapacity = data.maxCapacity;
                this.MyMinCapacity = data.capacity;
                this.fastMenuItems = data.fastSlots || [];

                this.initializeDragAndDrop();
            } else if (event.data.action === 'refreshInventory') {
                this.items = Object.values(data.items || {});
                this.MyMaxCapacity = data.maxCapacity;
                this.MyMinCapacity = data.capacity;
                this.fastMenuItems = data.fastSlots || [];
            } else if (event.data.action === 'openVault') {
                this.vaultData.active = true;
                this.vaultData.items = Object.values(data.items);
                this.vaultData.maxCapacity = data.maxCapacity;
                this.vaultData.capacity = data.capacity;
                this.vaultData.currentVaultName = data.currentVaultName;

                this.rightSide = data.rightSide;
            } else if (event.data.action === 'refreshVault') {
                this.vaultData.items = Object.values(data.items);
                this.vaultData.maxCapacity = data.maxCapacity;
                this.vaultData.capacity = data.capacity;
                this.vaultData.currentVaultName = data.currentVaultName;

                this.rightSide = data.rightSide;
            } else if (event.data.action === 'showAmmoSelect') {
                const item = this.items.find(i => i.name === event.data.data.ammoType);
                if (item) {
                    this.showCount('ammo', item, event.data.data.weaponName);
                }
            } else if (event.data.action === 'copyToClipboard') {
                const input = document.createElement('input');
                input.value = event.data.data.text;
                document.body.appendChild(input);
                input.select();
                document.execCommand('copy');
                document.body.removeChild(input);
            }
        },

        useItem(item) {
            this.post('utils:callServerEvent', {
                eventName: 'server:useItem',
                args: [item.name]
            });

            if (item.type !== 'ammo') {
                this.closeInventory();
            }
        },

        closeInventory() {
            $('.inventory').fadeOut(100);
            this.post("closeInventory");

            setTimeout(() => {
                this.vaultData.active = false;
                this.rightSide = {
                    name: 'Right Side',
                    desc: 'Here you can do different actions'
                };
                this.vaultData.items = [];
                this.vaultData.maxCapacity = 100;
                this.vaultData.capacity = 0;
                this.vaultData.currentVaultName = '';
            }, 100);
        },

        getItemTotalWeight(item) {
            return item.weight * item.count;
        },

        hideElement(id) {
            var div = document.getElementById(id);
            div.style.opacity = 0;
            div.style.left = 0;
            div.style.top = 0;
        },

        previewItem(name, label, count, type, usable) {
            const itemElement = $(event.currentTarget);
            const elementPosition = itemElement.offset();
            const itemWidth = itemElement.width();

            const modalPosition = {
                left: `${elementPosition.left + itemWidth + 10}px`,
                top: `${elementPosition.top}px`
            };

            this.previewModal.item = { name, label, count, type, usable };
            this.previewModal.style = modalPosition;
            this.previewModal.show = true;

            $(document).on('click', (e) => {
                if (!$(e.target).closest('.inventory__modal--container').length) {
                    this.previewModal.show = false;
                    $(document).off('click');
                }
            });
        },

        showCount(type, item, event) {
            this.countModal.type = type;
            this.countModal.item = { ...item };
            this.countModal.selectedCount = 1;

            if (type === 'ammo') {
                const itemElement = $(`.menu__list-item img[src$="${item.name}.png"]`).parent();
                const position = itemElement.offset();
                const itemWidth = itemElement.width();

                this.countModal.style = {
                    left: `${position.left + itemWidth + 10}px`,
                    top: `${position.top}px`
                };
            } else if (event) {
                this.countModal.style = {
                    left: `${event.pageX}px`,
                    top: `${event.pageY}px`
                };
            } else {
                this.countModal.style = this.previewModal.style;
            }

            this.countModal.show = true;
            this.previewModal.show = false;

            $(document).on('click', (e) => {
                if (!$(e.target).closest('.inventory__modal--container').length && !$(e.target).hasClass('nohide')) {
                    this.countModal.show = false;
                    $(document).off('click');
                }
            });
        },

        adjustCount(amount) {
            const newCount = this.countModal.selectedCount + amount;
            if (newCount >= 0 && newCount <= this.countModal.item.count && newCount !== 0) {
                this.countModal.selectedCount = newCount;
            }
        },

        handleInventoryAction() {
            if (this.countModal.type === 'drop') {
                const itemIndex = this.items.findIndex(item => item.name === this.countModal.item.name);

                if (itemIndex !== -1) {
                    const item = this.items[itemIndex];

                    this.post("utils:callServerEvent", {
                        eventName: "server:dropItem",
                        args: [item.name, this.countModal.selectedCount, true]
                    });
                }
            } else if (this.countModal.type === 'give') {
                const item = this.countModal.item;

                this.post('utils:callServerEvent', {
                    eventName: 'server:giveItemToPlayer',
                    args: [item, this.countModal.selectedCount]
                });
            } else if (this.countModal.type === 'vault') {
                const item = this.countModal.item;

                this.post('utils:callServerEvent', {
                    eventName: 'server:giveItemToVault',
                    args: [item, this.countModal.selectedCount, this.vaultData.currentVaultName]
                });
            } else if (this.countModal.type === 'inventory') {
                const item = this.countModal.item;

                this.post('utils:callServerEvent', {
                    eventName: 'server:moveItemFromVault',
                    args: [item, this.countModal.selectedCount, this.vaultData.currentVaultName]
                });
            } else if (this.countModal.type === 'ammo') {
                const item = this.countModal.item;

                this.post('loadAmmo', {
                    ammoType: item.name,
                    amount: this.countModal.selectedCount,
                });

                this.countModal.show = false;
                return;
            }

            this.countModal.show = false;

            this.$nextTick(() => {
                this.initializeDragAndDrop();
            });
        },

        initializeDragAndDrop() {
            $('.menu__list-item, .fastmenu__item').draggable({
                helper: 'clone',
                revert: 'invalid',
                containment: 'window',
                scroll: false,
                zIndex: 100,
                cursor: 'default',
                start: (event, ui) => {
                    const index = $(event.target).index();
                    const parentId = $(event.target).parent().attr('id');

                    let hasItem = false;
                    if (parentId === 'inventory-itemlist') {
                        hasItem = !!this.filteredItems[index];
                    } else if (parentId === 'vault-itemlist') {
                        if (!this.vaultData.active) return false;
                        hasItem = !!this.filteredVaultItems[index];
                    } else if (parentId === 'fastmenu__items') {
                        hasItem = !!this.fastMenuItems[index];
                    }

                    if (!hasItem) {
                        return false;
                    }

                    $(ui.helper).addClass('item-being-dragged');
                    $(ui.helper).css('cursor', 'default');
                }
            });

            $('#inventory-itemlist').droppable({
                accept: '.menu__list-item, .fastmenu__item',
                cursor: 'default',
                drop: (event, ui) => {
                    const draggedItemIndex = $(ui.draggable).index();
                    const draggedFromId = $(ui.draggable).parent().attr('id');

                    if (draggedFromId === 'vault-itemlist') {
                        const item = this.filteredVaultItems[draggedItemIndex];
                        if (item) {
                            if (item.count === 1) {
                                this.moveItemFromVault(draggedItemIndex);
                            } else {
                                this.showCount('inventory', item, event.originalEvent);
                            }
                        }
                    } else if (draggedFromId === 'fastmenu__items') {
                        this.moveItemFromFastMenu(draggedItemIndex);
                    }
                }
            });

            $('.fastmenu__item').droppable({
                accept: '.menu__list-item',
                cursor: 'default',
                drop: async (event, ui) => {
                    const draggedItemIndex = $(ui.draggable).index();
                    const dropSlotIndex = $(event.target).index();
                    const draggedFromId = $(ui.draggable).parent().attr('id');

                    if (draggedFromId === 'inventory-itemlist') {
                        this.moveItemToFastMenu(draggedItemIndex, dropSlotIndex);
                    }
                }
            });

            $('#vault-itemlist .menu__list-item').droppable({
                accept: '.menu__list-item',
                cursor: 'default',
                drop: async (event, ui) => {
                    if (!this.vaultData.active) {
                        return false;
                    }

                    const draggedItemIndex = $(ui.draggable).index();
                    const draggedFromId = $(ui.draggable).parent().attr('id');

                    if (draggedFromId === 'inventory-itemlist') {
                        const item = this.filteredItems[draggedItemIndex];
                        if (item) {
                            if (item.count === 1) {
                                this.moveItemToVault(draggedItemIndex);
                            } else {
                                this.showCount('vault', item, event.originalEvent);
                            }
                        }
                    }
                }
            });
        },

        moveItemToFastMenu(fromIndex, toSlot) {
            const item = this.filteredItems[fromIndex];
            if (!item) return;

            this.post('utils:callServerEvent', {
                eventName: 'server:setFastSlot',
                args: [toSlot + 1, item]
            });

            this.$nextTick(() => {
                this.initializeDragAndDrop();
            });
        },

        moveItemToVault(fromIndex) {
            if (!this.vaultData.active) {
                return;
            }

            const item = this.filteredItems[fromIndex];
            if (!item) return;

            this.post('utils:callServerEvent', {
                eventName: 'server:giveItemToVault',
                args: [item, 1, this.vaultData.currentVaultName]
            });

            this.$nextTick(() => {
                this.initializeDragAndDrop();
            });
        },

        moveItemFromVault(fromIndex) {
            const item = this.filteredVaultItems[fromIndex];
            if (!item) return;

            this.post('utils:callServerEvent', {
                eventName: 'server:moveItemFromVault',
                args: [item, 1, this.vaultData.currentVaultName]
            });

            this.$nextTick(() => {
                this.initializeDragAndDrop();
            });
        },

        moveItemFromFastMenu(fromIndex) {
            const item = this.fastMenuItems[fromIndex];
            if (!item) return;

            this.post('utils:callServerEvent', {
                eventName: 'server:removeItemFromFastSlot',
                args: [fromIndex + 1, item]
            });

            this.$nextTick(() => {
                this.initializeDragAndDrop();
            });
        },

        moveItemWithinFastMenu(fromIndex, toIndex) {
            const item = this.fastMenuItems[fromIndex];
            if (!item || fromIndex === toIndex) return;

            const tempItem = this.fastMenuItems[toIndex];
            this.$set(this.fastMenuItems, toIndex, item);
            this.$set(this.fastMenuItems, fromIndex, tempItem);

            this.$nextTick(() => {
                this.initializeDragAndDrop();
            });
        },

        giveItem(item) {
            if (!item) return;

            if (item.count === 1) {
                this.post('utils:callServerEvent', {
                    eventName: 'server:giveItemToPlayer',
                    args: [item, 1]
                });
                this.previewModal.show = false;
            } else {
                this.showCount('give', item);
            }
        }
    }
});
