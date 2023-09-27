#ifndef MONSTER_GR
#define MONSTER_GR "Pushin P"
//https://doomwiki.org/wiki/Thing_types
#define THINGS_FILE "ThingProps.TXT"

class CDoomThingTemplate {
  U8 spr_base_name[4],pad[4];
  U8 *animation;
  I64 height,radius,type;
#define TF_POWERUP 1
#define TF_ARTIFACT 2
#define TF_WEAPON 4
#define TF_MONSTER 8
#define TF_OBSTACLE 0x10
#define TF_SHOOTABLE 0x20
#define TF_FLOATING 0x40
  I64 flags;
} *doom_thing_types[0x10000];

class CDoomMonsterTemplate:CDoomThingTemplate {
  I64 code;
  F64 x,y,angle,pain_chance;
  F64 min_damage,max_damage;
  I64 hp,speed,mass;
  U8 *idle_frames;
  U8 *chase_frames;
  U8 *attack_frames;
  U8 *hurt_frames;
  U8 *dying_frames;
};

U8 *ReadALine(U8 **fbuf) {
  U8 *en,*st=*fbuf,*buf;
  if(!*st) return NULL;
  if(en=StrFirstOcc(st,"\n")) {
    buf=MAlloc(en-st+2);
    MemCpy(buf,st,en-st+1);
    buf[en-st+1]=0;
    *fbuf=en+1;
    return buf;
  }
  *fbuf+=StrLen(st);
  return StrNew(st);
}

U0 ParseThingProps() {
  MemSet(&doom_thing_types,0,8*0x10000);
  CDoomThingTemplate *template;
  U8 *fbuf=FileRead(THINGS_FILE),*line,*o=fbuf;
  U8 flags[STR_LEN],version[STR_LEN],desc[STR_LEN],sprite[STR_LEN],ani[STR_LEN];
  U8 *flagsp,*versionp,*descp,*spritep,*anip;
  I64 dec,hex;
  I64 radius,height;
  StrUtil(fbuf,SUF_REM_CTRL_CHARS); //Remove the poop CH_CURSOR
  while(line=ReadALine(&fbuf)) {
    if(line[0]=='#'||line[0]=='\n'||!StrLen(line))
      goto skip;
    versionp=&version;
    spritep=&sprite;
    anip=&ani;
    flagsp=&flags;
    descp=&desc;
    StrScan(line,"%d\t%X\t%s\t%d\t%d\t%s\t%s\t%s\t%s\n",
	  &dec,
	  &hex,
	  &versionp,
	  &radius,
	  &height,
	  &spritep,
	  &anip,
	  &flagsp,
	  &descp
	  );
    if(StrOcc(version,'2'))
      goto skip;
    template=CAlloc(sizeof CDoomThingTemplate);
    MemCpy(template->spr_base_name,sprite,4);
    template->radius=radius;
    template->height=height;
    template->animation=StrNew(ani);
    template->type=dec;
    for(flagsp=flags;*flagsp;flagsp++) {
      switch(&*flagsp) {
        case 'A':
	  template->flags|=TF_ARTIFACT;
	  break;
        case 'P':
	  template->flags|=TF_POWERUP;
	  break;
        case 'W':
	  template->flags|=TF_WEAPON;
	  break;
        case 'M':
	  template->flags|=TF_MONSTER;
	  break;
        case 'O':
	  template->flags|=TF_OBSTACLE;
	  break;
        case '*':
	  template->flags|=TF_SHOOTABLE;
	  break;
        case '^':
	  template->flags|=TF_FLOATING;
	  break;
      }
    }
    doom_thing_types[dec]=template;
skip:
    Free(line);
  }
  Free(o);
}
ParseThingProps;

CDC *GetThingFaceSprite(CDoomThingTemplate *template,F64 angle,U8 ani_frame='A',Bool *reflect=NULL) {
  I64 face=1,try_face;
  F64 gap_inc=2.*pi/8.,gap;
  CDC *ret;
  angle=Wrap(angle,0);
  if(reflect) *reflect=FALSE;
  for(gap=-gap_inc/2;gap<=2*pi;gap+=gap_inc) {
    if(gap<=angle<=gap+gap_inc)
      break;
    face++;
  }
  U8 buttplate[9];
  buttplate[8]=0;
  MemCpy(buttplate,template->spr_base_name,4);
  buttplate[4]=ani_frame;
//TROO[frame]0 //All roations
  buttplate[5]='0';
  buttplate[6]=0;
  if(ret=FramePtr(buttplate))
    return ret;
//TROO[frame][rotaionface]
  buttplate[5]='0'+face;
  if(ret=FramePtr(buttplate))
    return ret;
//TROO[frame][rotaionface][frame][reflected_face]
  buttplate[6]=ani_frame;
  for(try_face=0;try_face!=9;try_face++) {
    buttplate[7]=try_face+'0';
    if(ret=FramePtr(buttplate)) {
       if(reflect) *reflect=TRUE;
       return ret;
    }
  }
//Try opposite order
  buttplate[7]='0'+face;
  for(try_face=0;try_face!=9;try_face++) {
    buttplate[5]=try_face+'0';
    if(ret=FramePtr(buttplate)) {
       return ret;
    }
  }
  return NULL; 
}
#endif