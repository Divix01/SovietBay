/*	Photography!
 *	Contains:
 *		Camera
 *		Camera Film
 *		Photos
 *		Photo Albums
 */

/*******
* film *
*******/
/obj/item/device/camera_film
	name = "film cartridge"
	icon = 'icons/obj/items.dmi'
	desc = "A camera film cartridge. Insert it into a camera to reload it."
	icon_state = "film"
	item_state = "electropack"
	w_class = 1.0


/********
* photo *
********/
var/global/photo_count = 0

/obj/item/weapon/photo
	name = "photo"
	icon = 'icons/obj/items.dmi'
	icon_state = "photo"
	item_state = "paper"
	w_class = 1
	var/id
	var/icon/img	//Big photo image
	var/scribble	//Scribble on the back.
	var/icon/tiny

/obj/item/weapon/photo/New()
	id = photo_count++

/obj/item/weapon/photo/attack_self(mob/user as mob)
	user.examinate(src)

/obj/item/weapon/photo/attackby(obj/item/weapon/P as obj, mob/user as mob)
	if(istype(P, /obj/item/weapon/pen))
		var/txt = sanitize(input(user, "What would you like to write on the back?", "Photo Writing", null)  as text, 128)
		if(loc == user && user.stat == 0)
			scribble = txt
	..()

/obj/item/weapon/photo/examine(mob/user)
	if(in_range(user, src))
		show(user)
		user << desc
	else
		user << "<span class='notice'>It is too far away.</span>"

/obj/item/weapon/photo/proc/show(mob/user as mob)
	user << browse_rsc(img, "tmp_photo.png")
	user << browse(sanitize_local("<html><head><title>[name]</title></head>" \
		+ "<body style='overflow:hidden;margin:0;text-align:center'>" \
		+ "<img src='tmp_photo.png' width='192' style='-ms-interpolation-mode:nearest-neighbor' />" \
		+ "[scribble ? "<br>Written on the back:<br><i>[scribble]</i>" : ""]"\
		+ "</body></html>", "window=book;size=192x[scribble ? 400 : 192]", SANITIZE_BROWSER))
	onclose(user, "[name]")
	return

/obj/item/weapon/photo/verb/rename()
	set name = "Rename photo"
	set category = "Object"
	set src in usr

	var/n_name = sanitizeSafe(input(usr, "What would you like to label the photo?", "Photo Labelling", null)  as text, MAX_NAME_LEN)
	//loc.loc check is for making possible renaming photos in clipboards
	if(( (loc == usr || (loc.loc && loc.loc == usr)) && usr.stat == 0))
		name = "[(n_name ? text("[n_name]") : "photo")]"
	add_fingerprint(usr)
	return


/**************
* photo album *
**************/
/obj/item/weapon/storage/photo_album
	name = "Photo album"
	icon = 'icons/obj/items.dmi'
	icon_state = "album"
	item_state = "briefcase"
	w_class = 3 //same as book
	storage_slots = DEFAULT_BOX_STORAGE //yes, that's storage_slots. Photos are w_class 1 so this has as many slots equal to the number of photos you could put in a box
	can_hold = list(/obj/item/weapon/photo)

/obj/item/weapon/storage/photo_album/MouseDrop(obj/over_object as obj)

	if((istype(usr, /mob/living/carbon/human)))
		var/mob/M = usr
		if(!( istype(over_object, /obj/screen) ))
			return ..()
		playsound(loc, "rustle", 50, 1, -5)
		if((!( M.restrained() ) && !( M.stat ) && M.back == src))
			switch(over_object.name)
				if("r_hand")
					M.u_equip(src)
					M.put_in_r_hand(src)
				if("l_hand")
					M.u_equip(src)
					M.put_in_l_hand(src)
			add_fingerprint(usr)
			return
		if(over_object == usr && in_range(src, usr) || usr.contents.Find(src))
			if(usr.s_active)
				usr.s_active.close(usr)
			show_to(usr)
			return
	return

/*********
* camera *
*********/
/obj/item/device/camera
	name = "camera"
	icon = 'icons/obj/items.dmi'
	desc = "A polaroid camera. 10 photos left."
	icon_state = "camera"
	item_state = "electropack"
	w_class = 2.0
	flags = CONDUCT
	slot_flags = SLOT_BELT
	matter = list(DEFAULT_WALL_MATERIAL = 2000)
	var/pictures_max = 10
	var/pictures_left = 10
	var/on = 1
	var/icon_on = "camera"
	var/icon_off = "camera_off"
	var/size = 3

/obj/item/device/camera/attack(mob/living/carbon/human/M as mob, mob/user as mob)
	return

/obj/item/device/camera/attack_self(mob/user as mob)
	on = !on
	if(on)
		src.icon_state = icon_on
	else
		src.icon_state = icon_off
	user << "You switch the camera [on ? "on" : "off"]."
	return

/obj/item/device/camera/attackby(obj/item/I as obj, mob/user as mob)
	if(istype(I, /obj/item/device/camera_film))
		if(pictures_left)
			user << "<span class='notice'>[src] still has some film in it!</span>"
			return
		user << "<span class='notice'>You insert [I] into [src].</span>"
		user.drop_item()
		qdel(I)
		pictures_left = pictures_max
		return
	..()

/obj/item/device/camera/proc/camera_get_icon(list/turfs, turf/center)
	var/atoms[] = list()
	for(var/turf/T in turfs)
		atoms.Add(T)
		for(var/atom/movable/A in T)
			if(A.invisibility)
				continue
			atoms.Add(A)

	var/list/sorted = list()
	var/j
	for(var/i = 1 to atoms.len)
		var/atom/c = atoms[i]
		for(j = sorted.len, j > 0, --j)
			var/atom/c2 = sorted[j]
			if(c2.layer <= c.layer)
				break
		sorted.Insert(j+1, c)

	var/icon/res = icon('icons/effects/96x96.dmi', "")

	for(var/atom/A in sorted)
		var/icon/img = getFlatIcon(A)

		/*
		FixIt Add "lying" *cry*
		if(istype(A, /mob/living) && A:lying)
			img.Turn(A:lying_current)
		*/

		var/offX = 32 * (A.x - center.x) + A.pixel_x + 33
		var/offY = 32 * (A.y - center.y) + A.pixel_y + 33
		if(istype(A, /atom/movable))
			offX += A:step_x
			offY += A:step_y

		res.Blend(img, blendMode2iconMode(A.blend_mode), offX, offY)

	for(var/turf/T in turfs)
		res.Blend(getFlatIcon(T.loc), blendMode2iconMode(T.blend_mode), 32 * (T.x - center.x) + 33, 32 * (T.y - center.y) + 33)

	return res

/obj/item/device/camera/proc/camera_get_mobs(turf/the_turf)
	var/mob_detail
	for(var/mob/M in the_turf)
		if(M.invisibility)
			continue

		var/holding = null

		if(istype(M, /mob/living))
			var/mob/living/L = M
			if(L.l_hand || L.r_hand)
				if(L.l_hand) holding = "They are holding \a [L.l_hand]"
				if(L.r_hand)
					if(holding)
						holding += " and \a [L.r_hand]"
					else
						holding = "They are holding \a [L.r_hand]"

			if(!mob_detail)
				mob_detail = "You can see [L] on the photo[L.health < 75 ? " - [L] looks hurt":""].[holding ? " [holding]":"."]. "
			else
				mob_detail += "You can also see [L] on the photo[L.health < 75 ? " - [L] looks hurt":""].[holding ? " [holding]":"."]."

	return mob_detail

/obj/item/device/camera/afterattack(atom/target as mob|obj|turf|area, mob/user as mob, flag)
	if(!on || !pictures_left || ismob(target.loc)) return
	captureimage(target, user, flag)

	playsound(loc, pick('sound/items/polaroid1.ogg', 'sound/items/polaroid2.ogg'), 75, 1, -3)

	pictures_left--
	desc = "A polaroid camera. It has [pictures_left] photos left."
	user << "<span class='notice'>[pictures_left] photos left.</span>"
	icon_state = icon_off
	on = 0
	spawn(64)
		icon_state = icon_on
		on = 1

//Proc for capturing check
/mob/living/proc/can_capture_turf(turf/T)
	var/mob/dummy = new(T)	//Go go visibility check dummy
	var/viewer = src
	if(src.client)		//To make shooting through security cameras possible
		viewer = src.client.eye
	var/can_see = (dummy in viewers(world.view, viewer))

	qdel(dummy)
	return can_see

/obj/item/device/camera/proc/captureimage(atom/target, mob/living/user, flag)
	var/mobs = ""
	var/list/turfs = list()
	for(var/turf/T in range(1, target))
		if(user.can_capture_turf(T))
			turfs += T
			mobs += camera_get_mobs(T)

	var/icon/temp = icon('icons/effects/96x96.dmi',"")
	temp.Blend("#000", ICON_OVERLAY)
	temp.Blend(camera_get_icon(turfs, target), ICON_OVERLAY)

	var/obj/item/weapon/photo/p = createpicture(user, temp, mobs, flag)
	printpicture(user, p)

/obj/item/device/camera/proc/createpicture(mob/user, icon/temp, mobs, flag)
	var/icon/small_img = icon(temp)
	var/icon/tiny_img = icon(temp)
	var/icon/ic = icon('icons/obj/items.dmi',"photo")
	var/icon/pc = icon('icons/obj/bureaucracy.dmi', "photo")
	small_img.Scale(8, 8)
	tiny_img.Scale(4, 4)
	ic.Blend(small_img,ICON_OVERLAY, 10, 13)
	pc.Blend(tiny_img,ICON_OVERLAY, 12, 19)

	var/obj/item/weapon/photo/P = new()
	P.icon = ic
	P.tiny = pc
	P.img = temp
	P.desc = mobs
	P.pixel_x = rand(-10, 10)
	P.pixel_y = rand(-10, 10)

	return P

/obj/item/device/camera/proc/printpicture(mob/user, var/obj/item/weapon/photo/P)
	P.loc = user.loc
	if(!user.get_inactive_hand())
		user.put_in_inactive_hand(P)

/obj/item/weapon/photo/proc/copy(var/copy_id = 0)
	var/obj/item/weapon/photo/p = new/obj/item/weapon/photo()

	p.name = name
	p.icon = icon(icon, icon_state)
	p.tiny = icon(tiny)
	p.img = icon(img)
	p.desc = desc
	p.pixel_x = pixel_x
	p.pixel_y = pixel_y
	p.scribble = scribble

	if(copy_id)
		p.id = id

	return p