import { SignalCounter } from "@rbxts/lemon-signal-counter";

interface Zone {
	// Methods
	findLocalPlayer(): boolean;
	findPlayer(player: Player): boolean;
	findPart(part: BasePart): LuaTuple<[boolean, BasePart[]]>;
	getCheckerPart(): BasePart;
	findItem(characterOrBasePart: BasePart | Model): LuaTuple<[boolean, BasePart[]]>;
	findPoint(point: Vector3 | CFrame): LuaTuple<[boolean, BasePart[]]>;
	getPlayers(): Player[];
	getParts(): BasePart[];
	getItems(): Array<BasePart | Model>;
	/**
	 * Generates random points within the zones region until one falls within its bounds.
	 * It then returns this Vector3 and a table array of group parts the point falls within.
	 */
	getRandomPoint(): LuaTuple<[Vector3, BasePart[]]> | undefined;
	/**
	 * This is used to detect your own custom instances within zones, such as NPCs, and is a recommended replacement for part-events/methods.
	 * An item can be any BasePart or Character/NPC (i.e. a model with a Humanoid and HumanoidRootPart). Once tracked, it can be listened for with the zone.itemEntered and zone.itemExited events.
	 * An item will be automatically untracked if destroyed or has its parent set to nil.
	 * @param item
	 */
	trackItem(characterOrBasePart: BasePart | Model): void;
	untrackItem(characterOrBasePart: BasePart | Model): void;
	/**
	 * This is used to bind the zone to a settingsGroup to enhance the default behaviour of a collection of zones. The properties of a settingsGroup can be viewed at and customised using ZoneController.setGroup.
	 * This method is particularly useful for zones where you want to guarantee the player/item is not in two zones at once. For example, when working with ambient/music/lighting zones which perfectly border each other.
	 */
	bindToGroup(settingsGroupName: string): void;
	unbindFromGroup(): void;
	setAccuracy(accuracy: Accuracy[keyof Accuracy]): void;
	/**
	 * Sets the precision of checks based upon the [Detection Enum]. Defaults to `Automatic`.
	 */
	setDetection(enumIdOrName: Detection[keyof Detection] | keyof Detection): void;
	/**
	 * Moves the zone outside of workspace into a separate WorldModel within ReplicatedStorage or ServerStorage. This action is irreversible - once called it cannot be undone.
	 * @param newParent
	 */
	relocate(newParent: Instance): void;
	/**
	 * Tracks the item until it has entered the zone, then calls the given function. If the item is already within the zone, the given function is called right away.
	 * ```lua
	 * local item = character:FindFirstChild("HumanoidRootPart")
	 * zone:onItemEnter(item, function()
	 *     print("The item has entered the zone!"))
	 * end)
	 * ```
	 */
	onItemEnter(characterOrBasePart: Model | BasePart, callback: () => void): void;
	/**
	 * Tracks the item until it has exited the zone, then calls the given function. If the item is already outside the zone, the given function is called right away.
	 *
	 * ```lua
	 * local item = character:FindFirstChild("HumanoidRootPart")
	 * zone:onItemExit(item, function()
	 *     print("The item has exited the zone!"))
	 * end)
	 * ```
	 */
	onItemExit(characterOrBasePart: Model | BasePart, callback: () => void): void;
	/**
	 * Disconnects all connections within the zone.
	 */
	destroy(): void;

	// Events
	readonly localPlayerEntered: SignalCounter<void>;
	readonly localPlayerExited: SignalCounter<void>;
	readonly playerEntered: SignalCounter<Player>;
	readonly playerExited: SignalCounter<Player>;
	readonly partEntered: SignalCounter<BasePart>;
	readonly partExited: SignalCounter<BasePart>;
	readonly itemEntered: SignalCounter<BasePart | Model>;
	readonly itemExited: SignalCounter<BasePart | Model>;

	// Properties
	/**
	 * To change accuracy it's recommended you use setAccuracy.
	 */
	readonly accuracy: Accuracy[keyof Accuracy];
	/**
	 * To change both detection types use [setDetection] otherwise to set individually do:
	 */
	enterDetection: Detection[keyof Detection];
	/**
	 * To change both detection types use [setDetection] otherwise to set individually do:
	 */
	exitDetection: Detection[keyof Detection];
	/**
	 * When true, the zone will update when its group parts change size or position, or when a descendant group part is added or removed from the group.
	 */
	autoUpdate: boolean;
	/**
	 * When true, will prevent the internal _update() from being called multiple times within a 0.1 second period.
	 */
	respectUpdateQueue: boolean;
	/**
	 * An array of baseparts, defined in the group constructor parameter, that form the zone.
	 */
	readonly zoneParts: BasePart[];
	readonly region: Region3;
	readonly volume: number;
	readonly worldModel: WorldModel;
}

interface ZoneConstructor {
	/**
	 * A container is used the define the boundaries of the zone. It can be any non-basepart instance (such as a Model, Folder, etc) that contain descendant baseparts. Alternatively a container can be a singular basepart instance, or a table containing an array of baseparts.
	 * @param container A model, folder, basepart or array of baseparts.
	 */
	new (container: Container): Zone;
	/**
	 * Constructs a zone from the given CFrame and Size. Underneath the hood, it's creating a part (or multiple parts if any size coordinage exceeds 2024), parenting this to a folder (the container), constructing a zone with this container, calling :relocate() on that zone (which parents it outside of workspace), then finally returning the zone.
	 */
	fromRegion: (cframe: CFrame, size: Vector3) => Zone;
}

declare const Zone: ZoneConstructor;
export = Zone;
